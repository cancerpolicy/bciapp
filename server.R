# Setup: libraries and functions
# A note about deploying: 
# rsconnect::deployApp('/Users/jeanette/Documents/jbirnbau/bciapp', account='cancerpolicy', appName='breastcancer')
library(shiny)
library(parallel)
library(ggplot2)
library(reshape2)
library(plyr)
source('code.R')
#install_github('cancerpolicy/bcimodel')
library(bcimodel)

shinyServer(function(input, output, session) {
  
################################################################################
# DEBUGGER
################################################################################
if (1==0) {
output$debug <- renderPrint({
    as.character(print_vec(a0t.reactive()))
})
}

output$debug5 <- renderPrint({
    as.character(c(input$agerange, input$incCountry, input$mortCountry,
                   input$prop_a0, input$prop_a1, prop_s()))
})
output$debug4 <- renderTable({
    datain.scenarios()
})
output$debug3 <- renderTable({
    datain.map()
})
output$debug2 <- renderTable({
    datain.tx()
})
output$debug <- renderTable({
    datain.nh()
})


################################################################################
# INCIDENCE AND MORTALITY CHOICES
################################################################################

output$chooseInc <- renderUI({
    data(incratesf)
    countries <- as.character(unique(incratesf$Country))
    selectizeInput('incCountry', '',
                   choices=countries,
                   selected='Uganda',
                   options=list(maxItems=1, placeholder='Uganda'))
})
output$chooseMort <- renderUI({
    data(allmortratesf)
    countries <- as.character(unique(allmortratesf$Country))
    selectizeInput('mortCountry', '',
                   choices=countries,
                   selected='Uganda',
                   options=list(maxItems=1, placeholder='Uganda'))
})

output$inccountry <- renderText({
    input$incCountry
})
output$mortcountry <- renderText({
    input$mortCountry
})

################################################################################
# CONVERT FROM PERCENTS TO PROPORTIONS
################################################################################
prop_ERpos <- reactive({ input$prop_ERpos/100 })
surv.adv <- reactive({ input$surv.adv/100 })
surv.early <- reactive({ input$surv.early/100 })
prop_a0 <- reactive({ input$prop_a0/100 })
prop_a1 <- reactive({ input$prop_a1/100 })
tam.prop.control <- reactive({ input$tam.prop.control/100 })
chemo.prop.control <- reactive({ input$chemo.prop.control/100 })
tam.prop.interv <- reactive({ input$tam.prop.interv/100 })
chemo.prop.interv <- reactive({ input$chemo.prop.interv/100 })

################################################################################
# COMPILE NATURAL HISTORY FOR bcimodel::simpolicies
################################################################################

datain.nh <- reactive({

    # Compute mortality rates from survival
    m.a=exp.rate(as.numeric(surv.adv()),
                 year=as.numeric(input$year.surv))
    m.e=exp.rate(as.numeric(surv.early()),
                 year=as.numeric(input$year.surv))

    return(
        compile_naturalhist(prop_adv=prop_a0(), 
                            mortrates=c(Early=m.e, Advanced=m.a),
                            #subgroup_probs=c(`ER-`=1-prop_ERpos(), `ER+`=prop_ERpos()))
                            subgroup_probs=c(`ER+`=prop_ERpos(), `ER-`=1-prop_ERpos()))
    )
})

################################################################################
# EARLY DETECTION
################################################################################

#-------------------------------------------------------------------------------
# Stage shift
#-------------------------------------------------------------------------------
prop_s <- reactive({ 1-(input$prop_a1/input$prop_a0) })

#-------------------------------------------------------------------------------
# Summary, to display to user
#-------------------------------------------------------------------------------
output$edsummary <- renderTable({
    data.frame(Parameter=c('Percent advanced stage, standard of care', 
                           'Percent advanced stage, intervention', 
                           'Percent reduction in advanced stage due to intervention'),
               Value=c(input$prop_a0, input$prop_a1, 100*prop_s()))
}, digits=0)

#-------------------------------------------------------------------------------
# Map of stage-shift pairs for input into bcimodel::simpolicies
#-------------------------------------------------------------------------------
datain.map <- reactive({
    create_stageshift_map(datain.nh())
})

################################################################################
# PROCESS CONTROL & INTERVENTION SCENARIOS for bcimodel::simpolicies
################################################################################

datain.scenarios <- reactive({
    if (prop_s()==0) pairnum <- c(NA, NA) else pairnum <- c(NA, 1)

    return(
           data.frame(num=1:2,
                      id=c('control', 'intervention'),
                      name=c('Standard of Care', 'Intervention'),
                      pairnum=pairnum,
                      earlydetHR=c(1, 1-prop_s()),
                      stringsAsFactors=FALSE)
           )
})


################################################################################
# PROCESS TREATMENT-TUMOR SUBGROUP PROPORTIONS
################################################################################

#-------------------------------------------------------------------------------
# Control treatments
#-------------------------------------------------------------------------------

# Advanced
a0t.reactive <- reactive({
    treatvec <- treattumor_props_altorder('Advanced',
                                             input$tam.elig.control,
                                             as.numeric(tam.prop.control()),
                                             input$chemo.elig.control,
                                             as.numeric(chemo.prop.control()))
    return(treatvec)
})
output$a0tERpos <- renderUI({
    textInput('prop.a0.t.ERpos', 'ER+', 
                paste(as.character(a0t.reactive()[1:4]),collapse=','))
})
output$a0tERneg <- renderUI({
    textInput('prop.a0.t.ERneg', 'ER-', 
              paste(as.character(a0t.reactive()[5:8]),collapse=','))
})

# Early
e0t.reactive  <- reactive({
    treatvec <- treattumor_props_altorder('Early',
                                 input$tam.elig.control,
                                 as.numeric(tam.prop.control()),
                                 input$chemo.elig.control,
                                 as.numeric(chemo.prop.control()))
    return(treatvec)
})
output$e0tERpos <- renderUI({
    textInput('prop.e0.t.ERpos', 'ER+', 
              paste(as.character(e0t.reactive()[1:4]),collapse=','))
})
output$e0tERneg <- renderUI({
    textInput('prop.e0.t.ERneg', 'ER-', 
              paste(as.character(e0t.reactive()[5:8]),collapse=','))
})

#-------------------------------------------------------------------------------
# Intervention treatments
#-------------------------------------------------------------------------------

# Advanced
a1t.reactive <- reactive({
    treatvec <- treattumor_props_altorder('Advanced',
                                 input$tam.elig.interv,
                                 as.numeric(tam.prop.interv()),
                                 input$chemo.elig.interv,
                                 as.numeric(chemo.prop.interv()))
    return(treatvec)
})
output$a1tERpos <- renderUI({
    textInput('prop.a1.t.ERpos', 'ER+', 
              paste(as.character(a1t.reactive()[1:4]),collapse=','))
})
output$a1tERneg <- renderUI({
    textInput('prop.a1.t.ERneg', 'ER-', 
              paste(as.character(a1t.reactive()[5:8]),collapse=','))
})

# Early
e1t.reactive <- reactive({
    treatvec <- treattumor_props_altorder('Early',
                                 input$tam.elig.interv,
                                 as.numeric(tam.prop.interv()),
                                 input$chemo.elig.interv,
                                 as.numeric(chemo.prop.interv()))
    return(treatvec)
})
output$e1tERpos <- renderUI({
    textInput('prop.e1.t.ERpos', 'ER+', 
              paste(as.character(e1t.reactive()[1:4]),collapse=','))
})
output$e1tERneg <- renderUI({
    textInput('prop.e1.t.ERneg', 'ER-', 
              paste(as.character(e1t.reactive()[5:8]),collapse=','))
})

#-------------------------------------------------------------------------------
# Compile into data frame for input into bcimodel::simpolicies
#-------------------------------------------------------------------------------
no_update <- reactive({ is.null(input$prop.a1.t.ERpos) })
output$e0t <- renderPrint({ cat(is.null(input$prop.e1.t.ERneg)) })

e0t.updated <- reactive({
    if (no_update()) {
        return(e0t.reactive())
    } else {
        return(c(as.numeric(strsplit(input$prop.e0.t.ERpos, ',')[[1]]),
                 as.numeric(strsplit(input$prop.e0.t.ERneg, ',')[[1]]))
        )
    }
})

a0t.updated <- reactive({
    if (no_update()) {
        return(a0t.reactive())
    } else {
        return(
            c(as.numeric(strsplit(input$prop.a0.t.ERpos, ',')[[1]]),
              as.numeric(strsplit(input$prop.a0.t.ERneg, ',')[[1]]))
        )
    }
})

e1t.updated <- reactive({
    if (no_update()) {
        return(e1t.reactive())
    } else {
        return(
            c(as.numeric(strsplit(input$prop.e1.t.ERpos, ',')[[1]]),
              as.numeric(strsplit(input$prop.e1.t.ERneg, ',')[[1]]))
        )
    }
})

a1t.updated <- reactive({
    if (no_update()) {
        return(a1t.reactive())
    } else {
        c(as.numeric(strsplit(input$prop.a1.t.ERpos, ',')[[1]]),
          as.numeric(strsplit(input$prop.a1.t.ERneg, ',')[[1]]))
    }
})

# This relies on the ordering of subgroups and treatments defined in treattumor_props
datain.tx <- reactive({
    # Update the treatment vectors IF advanced controls have been used
    # I'm trying to allow users to bypass advanced treatment controls and still
    # have the treatment initialized properly. If the first vector input
    # is null, they haven't clicked on the advanced control page
    
    # Create treatment data frame
    data.frame(SSno=c(1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4),
               SSid=c(rep('Early.ER+',4),
                      rep('Early.ER-',4),
                      rep('Advanced.ER+',4),
                      rep('Advanced.ER-',4)),
               txSSno=1:16,
               txSSid=rep(c('None', 'Tamoxifen', 'Chemo', 'Tamoxifen+Chemo'), 4),
               #txHR=rep(c(0.775, 1, 0.775, 1, 0.5425, 0.7, 0.775, 1), 2),
               txHR=rep(c(1, 0.7, 0.775, 0.5425, 1, 1, 0.775, 0.775), 2),
               control=c(e0t.updated(), a0t.updated()),
               intervention=c(e1t.updated(), a1t.updated()),
               stringsAsFactors=FALSE)
})

################################################################################
# CHECK WHETHER SCENARIOS ARE PAIRED, AND FINALIZE INPUTS TO SIMPOLICIES
################################################################################
#-------------------------------------------------------------------------------
# If there is early detection in the intervention, does the base have the same
# treatments? That's what it means to be paired
#-------------------------------------------------------------------------------
check <- reactive({
    return(check_scenarios(datain.scenarios(), datain.tx()))
})

#-------------------------------------------------------------------------------
# Create final scenario data frame
#-------------------------------------------------------------------------------

final.scenarios <- reactive({
    if (length(check())==1) {
        return(datain.scenarios())
    } else {
        # We're going to insert an additional scenario that has the 
        # same treatments as the intervention, but no early detection
        df <- rbind(datain.scenarios(),
                    datain.scenarios()[2,])
        
        df$num[3] <- 3
        df$id[2] <- 'temp'
        df$name[2] <- 'Temp'
        df$pairnum[2:3] <- c(NA, 2)
        df$earlydetHR[2] <- 1
        
        return(df)
    }
})

#-------------------------------------------------------------------------------
# Create final treatment data frame
#-------------------------------------------------------------------------------
final.tx <- reactive({
    if (length(check())==1) {
        return(datain.tx())
    } else {
        # We're going to insert an additional scenario that has the 
        # same treatments as the intervention, but no early detection
        df <- cbind(datain.tx(),
                    datain.tx()[,'intervention'])
        colnames(df)[ncol(df)] <- 'temp'
        return(df)
    }
})

#-------------------------------------------------------------------------------
# Define columns to display in results
#-------------------------------------------------------------------------------
resultsCols <- reactive({
    if (length(check())==1) return(c(1,2)) else return(c(1,3))
})

#-------------------------------------------------------------------------------
# For debugging - will only display the final reactive
#-------------------------------------------------------------------------------

output$checkScenarios <- renderPrint({
    cat('\n\nResult of check_scenarios for raw inputs is:\n')
    check()
    cat('\n\nFinal scenario input data frame is:\n')
    final.scenarios()
    cat('\n\nFinal treatment input data frame is:\n')
    final.tx()
    cat('\nResults cols will be\n')
    resultsCols()
})

################################################################################
# PARAMETER SUMMARY TABLES
################################################################################

output$paramsum1 <- renderTable({
  data.frame(Parameter=c('Percent ER+',
                         'Percent surviving k years, advanced stage',
                         'Percent surviving k years, early stage',
                         'Percent presenting in advanced stage, standard of care',
                         'Percent presenting in advanced stage, intervention'
                         ),
             Value=c(input$prop_ERpos,
                       input$surv.adv,
                       input$surv.early,
                       input$prop_a0,
                       input$prop_a1))

}, NA.string='-')
output$paramsum2 <- renderTable({
  data.frame(`ER Status`=c('ER+', '', '', '', '',
                           'ER-', '', '', '', ''),
             Treatment=
                 c(rep(c('', 'None', 'Endocrine', 'Chemo', 'Endocrine+Chemo'),2))
             ,
             `Standard of Care`=c(NA,
                       100*a0t.reactive()[c('ERpos.None', 'ERpos.Tam', 'ERpos.Chemo', 
                                        'ERpos.TamChemo')],
                       NA,
                       100*a0t.reactive()[c('ERneg.None', 'ERneg.Tam', 'ERneg.Chemo', 
                                        'ERneg.TamChemo')]),
             Intervention=c(NA,
                       100*a1t.reactive()[c('ERpos.None', 'ERpos.Tam', 'ERpos.Chemo', 
                                        'ERpos.TamChemo')],
                       NA,
                       100*a1t.reactive()[c('ERneg.None', 'ERneg.Tam', 'ERneg.Chemo', 
                                          'ERneg.TamChemo')]),
             check.names=FALSE)

}, NA.string='', digits=0)
output$paramsum3 <- renderTable({
  data.frame(`ER Status`=c('ER+', '', '', '', '',
                           'ER-', '', '', '', ''),
             Treatment=
                 c(rep(c('', 'None', 'Endocrine', 'Chemo', 'Endocrine+Chemo'),2))
             ,
             `Standard of Care`=c(NA,
                       100*e0t.reactive()[c('ERpos.None', 'ERpos.Tam', 'ERpos.Chemo', 
                                        'ERpos.TamChemo')],
                       NA,
                       100*e0t.reactive()[c('ERneg.None', 'ERneg.Tam', 'ERneg.Chemo',
                                            'ERneg.TamChemo')]),
             Intervention=c(NA,
                       100*e1t.reactive()[c('ERpos.None', 'ERpos.Tam', 'ERpos.Chemo', 
                                        'ERpos.TamChemo')],
                       NA,
                       100*e1t.reactive()[c('ERneg.None', 'ERneg.Tam', 'ERneg.Chemo',
                                            'ERneg.TamChemo')]),
             check.names=FALSE)

}, NA.string='', digits=0)
# Later, use this thread to improve formatting in the table
# https://groups.google.com/forum/#!topic/shiny-discuss/2jlYOYFp2-A
output$hazards <- renderTable({
  data.frame(`ER Status`=c('ER+', '', '', '',
                           'ER-', ''),
             Treatment=
                 c('', 'Endocrine', 'Chemo', 'Endocrine+Chemo', '', 'Chemo')
             ,
             `Hazard Ratio`=
                 c(NA, 0.7, 0.775, 0.5425, NA, 0.775),
             `Implied % Improvement in Survival`=
                 c(NA, 30, 22.5, 45.75, NA, 22.5),
             check.names=FALSE)

}, NA.string='', digits=3)

################################################################################
# RESULTS
################################################################################
#-------------------------------------------------------------------------------
# Tables - mean
#-------------------------------------------------------------------------------

runresults <- reactive({
    start <- proc.time()
     
    results <- simpolicies(scenarios=final.scenarios(),
                       naturalhist=datain.nh(),
                       treatinfo=final.tx(),
                       agesource='Standard',
                       minage=as.numeric(input$agerange[1]),
                       maxage=as.numeric(input$agerange[2]),
                       incsource=input$incCountry,
                       mortsource=input$mortCountry,
                       futimes=c(10,20),
                       returnstats=c('mean', 'lower', 'upper'),
                       popsize=input$popsize,
                       sims=input$nsim)
    runtime_minutes <- (proc.time()-start)/60
    return(list(runtime=runtime_minutes, results=results))
})

runtime <- reactive({
    return(round(runresults()$runtime['elapsed'], 2))
})

results <- reactive({
    return(runresults()$results)
})

output$runTime <- renderPrint({
    cat('\n\nRun time in minutes:', runtime())
})

#output$caption5 <- renderText({
#    if (!is.null(results())) { 
#            paste('Cumulative incidence of breast cancer is', results()[['5']]$mean[1,1])
#    } else 'Waiting for results...'
#})
output$caption10 <- renderText({
    if (!is.null(results())) { 
            paste('Cumulative incidence of breast cancer is', results()[['10']]$mean[1,1])
    } else 'Waiting for results...'
})
output$caption20 <- renderText({
    if (!is.null(results())) { 
            paste('Cumulative incidence of breast cancer is', results()[['20']]$mean[1,1])
    } else 'Waiting for results...'
})
#output$resultsTable5 <- renderTable({
#    results()[['5']]$mean[2:6,]
#}, digits=2, include.rownames=TRUE)
output$resultsTable10 <- renderTable({
    results()[['10']]$mean[2:6, resultsCols()]
}, digits=2, include.rownames=TRUE)
output$resultsTable20 <- renderTable({
    results()[['20']]$mean[2:6, resultsCols()]
}, digits=2, include.rownames=TRUE)

#-------------------------------------------------------------------------------
# Tables - uncertainty
#-------------------------------------------------------------------------------
uncertainty <- reactive({
    return(format_bounds_list(results(),
                              digits=c(0,0,1,2,1,0)))
})

#output$uncertaintyTable5 <- renderTable({
#    uncertainty()[['5']]
#}, rownames = TRUE)
output$uncertaintyTable10 <- renderTable({
    uncertainty()[['10']][, resultsCols()]
}, rownames = TRUE)
# }, align='c', include.rownames=TRUE)
output$uncertaintyTable20 <- renderTable({
    uncertainty()[['20']][, resultsCols()]
}, rownames = TRUE)
# }, rownames = TRUE, align='?cc')

#-------------------------------------------------------------------------------
# Debug table of results
#-------------------------------------------------------------------------------
output$debug5 <- renderTable({
    results <- results()
    if (1==0) {
        results <- lapply(results, function(x) {
            x <- data.frame(x$mean, check.names=FALSE)
            oldcols <- colnames(x)
            x$Statistic <- rownames(x)
            colnames(x)  <-  c(oldcols, 'Statistic')
            return(x)
        })
        results <- ldply(results, .id='Year')    
        return(results)
    } else return(results[['10']]$mean)
})

#-------------------------------------------------------------------------------
# Graph
#-------------------------------------------------------------------------------
output$resultsGraph <- renderPlot({
    results <- results()
    results <- lapply(results, function(x) {
                          x <- data.frame(x$mean, check.names=FALSE)
                          oldcols <- colnames(x)
                          x$Statistic <- rownames(x)
                          colnames(x)  <-  c(oldcols, 'Statistic')
                          return(x)
             })
    results <- ldply(results, .id='Year')
    # If there was a Temp scenario inserted, remove it
    if (ncol(results)==5) results <- results[,c(1,2,4,5)]
    colnames(results)[2:3] <- c('Standard of Care', 'Intervention') 
    results <- results[,c('Year', 'Statistic', 'Standard of Care', 'Intervention')]
    results <- transform(results, 
                         `Gained by Intervention`=Intervention-`Standard of Care`, 
                         check.names=FALSE)
    sl <- subset(melt(results, id.vars=c('Year', 'Statistic')),
                 Statistic=='% Incident Surviving' & variable!='Intervention')
    sl <- transform(sl, Percent=round(value))
    sl = ddply(sl, .(`Year`), transform, pos = (cumsum(Percent) - 0.5 * Percent))
    #sl$label = paste0(sprintf("%.0f", sl$Percent), "%")
    sl$label = as.character(sl$Percent)

    # The latest ggplot ordering is really annoying and has to be reversed
    if (!is.factor(sl$variable)) sl$variable <- factor(sl$variable)
    sl <- transform(sl, variable=factor(variable, levels=rev(levels(variable)),
                                       labels=rev(levels(variable))))

    g <- ggplot(sl, aes(x = factor(Year), y = Percent, fill = variable)) +
      geom_bar(stat = "identity", width = .7) +
      geom_text(aes(y = pos, label = label), size = 4) +
      theme(text = element_text(size=10)) + 
      scale_x_discrete(name='Years after intervention') + 
      scale_y_continuous('Percent of Incident Surviving',limits=c(0,100)) + 
      theme_bw()
    g + theme(legend.position='top') + theme(legend.title=element_blank()) +
        scale_fill_discrete(guide=guide_legend(reverse=TRUE))

})

})


