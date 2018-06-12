library(shiny)

shinyUI(fluidPage(
  
  titlePanel("Welcome to the breast cancer early detection and treatment impact model"),
  
  navlistPanel(
    tabPanel("Introduction",
             h3('Overview'),
             p('This interface allows you to model the survival benefit of a breast cancer screening and/or treatment intervention in a virtual population of your choosing.  The model posits a simple stage-shift mechanism of screening benefit. For more information, visit'), 
             a('http://cancerpolicy.github.io'),
             br(),
             h3('How to customize the model'),
             p('Specify inputs using the left panel to navigate. Parameters are numbered according to Table 1 in the accompanying manuscript.'),
             h3('Default model: breast cancer in East Africa'),
             p('The input defaults reflect an breast cancer example in East Africa. Under the standard of care, diagnosed cases receive surgery but no adjuvant treatment, and there is no early detection. We model an intervention in which endocrine therapy is offered to all ER+ women, and some cases are detected early through improved clinical access. This corresponds to policy E4 in the accompanying manuscript.')
    ),
    "Disease Features (#1-#3)",
    tabPanel('Age, incidence rates and ER status',
             h3('Define the age range of the population of interest'),
             p('The model will track outcomes for a cohort of women of these ages. Within the age range, ages are distributed using the WHO World Standard population.'),
             sliderInput('agerange', label='',
                          value=c(30, 49), min=0, max=100, step=1, 
                          width = NULL),
             h4(''),
             h3('Choose a country registry for age-specific incidence rates'),
             p('These data will determine the age at which women contract breast cancer, if at all.'),
             uiOutput('chooseInc'),
             em('Source: CI5-X Incidence Database'),
             a('http://ci5.iarc.fr/CI5-X/'),
             h4(''),
             h3('Specify estrogen receptor (ER) status'),
             p('The frequency of ER positivity varies across populations. ER+ tumors are receptive to endocrine therapy'),
             sliderInput("prop_ERpos", label = "Percent ER positive",
                         min=0, max=100, step=1, value=41)
    ),
    tabPanel("Stage distributions and early detection",
              h3('Enter the percent of advanced-stage cases under the two scenarios'),
              p('For each of the standard-of-care and intervention scenarios, this is the percent of cases who are advanced-stage at the time of clinical diagnosis. If the intervention is expected to detect cases early, the percent of cases diagnosed in advanced stage should be lower.'),
              p('The default intervention ... '),
             br(),
             sliderInput("prop_a0", label = "Percent advanced, standard of care",
                         min=0, max=100, step=1, value=78),
             sliderInput("prop_a1", label = "Percent advanced, intervention",
                         min=0, max=100, step=1, value=60),
             h4(''),
             h4(''),
             h4('Summary of specified stage distributions'),
             tableOutput('edsummary')
             ),
    "Treatment (#4-#5)",
    tabPanel("Distribution, Standard of Care",
              h3('Specify who is eligible for each treatment
                and what percent of eligible cases receive it under the standard of care'),
              p('Adjuvant treatment is rare in East Africa, so 
                we model no treatment for the Control Scenario.'),
              br(),
              h4('ENDOCRINE THERAPY'),
              radioButtons("tam.elig.control", "Who is eligible for endocrine therapy?",
                           c("All" = 'All',
                             "ER+ only" = 'ERpos')),
              sliderInput('tam.prop.control', label='What percent of eligible women receive endocrine therapy?', 
                          0, min = 0, max = 100, step = 1),
              br(),
              h4('CHEMOTHERAPY'),
              radioButtons("chemo.elig.control", "Who is eligible for chemotherapy?",
                          c("All" = 'All',
                            "ER- only" = 'ERneg',
                            "ER- and advanced-stage ER+" = 'ERnegERposAdv'
                            )),
              sliderInput('chemo.prop.control', label='What percent of eligible women receive chemotherapy?', 
                          0, min = 0, max = 100, step = 1)
              ),
    tabPanel("Distribution, Intervention",
             h3('Specify who is eligible for each treatment
                and what percent of eligible cases receive it under the intervention'),
             p('In the default intervention, all ER+ women receive endocrine therapy.'),
             br(),
             h4('ENDOCRINE THERAPY'),
             radioButtons("tam.elig.interv", "Who is eligible for endocrine therapy?",
                          c("All" = 'All',
                            "ER+ only" = 'ERpos'),
                          selected='ERpos'),
             sliderInput('tam.prop.interv', label='What percent of eligible women receive endocrine therapy?', 
                         100, min = 0, max = 100, step = 1),
             br(),
             h4('CHEMOTHERAPY'),
             radioButtons("chemo.elig.interv", "Who is eligible for chemotherapy?",
                          c("All" = 'All',
                            "ER- only" = 'ERneg',
                            "ER- and advanced-stage ER+" = 'ERnegERposAdv'
                          ),
                          selected='All'),
             sliderInput('chemo.prop.interv', label='What percent of eligible women receive chemotherapy?', 
                         0, min = 0, max = 100, step = 1)
    ),
    tabPanel("Efficacy",
             h3('The efficacy of treatment is sourced from the literature'),
             p('Meta-analyses from the Early Breast Cancer Trialists Collaborative Group
               have summarized the benefits of endocrine therapy and chemotherapy across
               regimens. The benefits are quantified as "hazard ratios" on survival, which
               indicate the percent improvement in survival due to treatment'),
             br(),
             h4('Hazard ratios, by ER status'),
             em('All treatments not specified in the table have a hazard ratio of 1,
                i.e. there is no impact on survival. So for example, endocrine therapy
                for ER- tumors has a hazard ratio of 1 and thus is not in the table.'),
             tableOutput('hazards'),
             p('References:'),
             em('1.
                Early Breast Cancer Trialists’ Collaborative Group (EBCTCG), Davies C, Godwin J, Gray R, Clarke M, Cutter D, et al. Relevance of breast cancer hormone receptors and other factors to the efficacy of adjuvant tamoxifen: patient-level meta-analysis of randomised trials. Lancet. 2011 Aug 27;378(9793):771–84. 
                '),
                br(),
             em('2.
                Early Breast Cancer Trialists’ Collaborative Group (EBCTCG), Peto R, Davies C, Godwin J, Gray R, Pan HC, et al. Comparisons between different polychemotherapy regimens for early breast cancer: meta-analyses of long-term outcome among 100,000 women in 123 randomised trials. Lancet. 2012 Feb 4;379(9814):432–44. 
                ')
             ),
    "Mortality (#6-#7)",
    tabPanel("Cancer survival",
              h4('Specify the percent of cases surviving at k years after diagnosis, or "baseline survival"'),
              p('Baseline survival should typically be survival in the absence of 
                systemic treatment, but it can be treated survival if the 
                intervention does not impact treatment. You must specify k-year 
                survival for advanced- and early-stage cases separately.'),
             br(),
             selectInput('year.surv', label='Year of survival statistic, k', 
                         choices=c(5,10), selected=5),
             
             sliderInput('surv.adv', label='Advanced cases: baseline survival at k years', 
                         35, min = 0, max = 100, step = 1),
             
             sliderInput('surv.early', label='Early cases: baseline survival at k years', 
                         69, min = 0, max = 100, step = 1)
             ),
    tabPanel("Other-cause mortality",
             h3('Select a country lifetable database for other-cause mortality'),
             p('These data will be used to model background mortality.'),
             h4(''),
             uiOutput('chooseMort'),
             em('Source: IHME 2013 Lifetable Estimates'), 
             a('http://ghdx.healthdata.org/global-burden-disease-study-2013-gbd-2013-data-downloads')
             ),
    "Advanced Settings",
    tabPanel("Cohort size and simulations",
             h3('The size of the simulated population and number of simulations influences uncertainty'),
             p('A smaller population and fewer simulations will run faster but give noisier results. We recommend beginning with the default of 100,000 women and 50 simulations, and increasing to 100 simulations for more precise years of life saved estimates.'),
             br(),
             sliderInput('popsize', label='Size of population',
                          value=100000, min=100000, max=10000000, step=900000),
             br(),
             sliderInput("nsim", label = "Number of simulations",
                         min=5, max=100, step=5, value=50)
    ),
#    tabPanel("Debugging",
#             tableOutput('debug'),
#             tableOutput('debug2'),
#             tableOutput('debug3'),
#             tableOutput('debug4'),
#             verbatimTextOutput('checkScenarios')
#    ),
    "Results",
    tabPanel("Review inputs",
              h3('Confirm selected parameters'),
             p('The parameters specified on the previous pages are summarized below.
               To make changes, revisit the previous pages.'),
             br(),
             h4('Incidence data from:'),
             textOutput('inccountry'),
             h4('Other-cause mortality data from:'),
             textOutput('mortcountry'),
             br(),
             h4('Disease features'),
             tableOutput('paramsum1'),
             br(),
             h4('Treatment distribution, advanced stage'),
             em('Values represent percents falling into each group. Columns
                should sum to 100% within each ER type'),
             tableOutput('paramsum2'),
             br(),
             h4('Treatment distribution, early stage'),
             em('Values represent percents falling into each group. Columns
                should sum to 100% within each ER type'),
             tableOutput('paramsum3')
             ),
    tabPanel("Point estimates",
             # This accesses the stylesheet, which just sets a 
             # location for the progress bar. Thanks to:
             # https://groups.google.com/forum/#!topic/shiny-discuss/VzGkfPqLWkY 
             # and https://github.com/johndharrison/Seed
             tags$head(
                tags$link(rel='stylesheet', type='text/css', href='styles.css'),
                tags$script(type="text/javascript", src="busy.js")
             ),
             h5('Results will appear when simulations are complete. 
                Expected wait time is approximately 15 minutes.'),
             em('Results are reported as statistics per 100,000 women'),

                    div(class = "busy",
                             p("Calculation in progress..."),
                                  img(src="ajax-loader.gif")
                                 ),

             h4('Among incident cases, percent surviving'),
             p('x-axis shows the year of follow-up. Orange indicates gains from the intervention.'),
             plotOutput('resultsGraph'),
#            verbatimTextOutput('debug'),
#            tableOutput('debug'),
#             h4('Results after 5 years'),
#             textOutput('caption5'),
#             tableOutput('resultsTable5'),
             br(),
             h4('Results after 10 years'),
             textOutput('caption10'),
             tableOutput('resultsTable10'),
             br(),
             h4('Results after 20 years'),
             textOutput('caption20'),
             tableOutput('resultsTable20'),
             h4('Model notes and run time'),
             p('Run time, in minutes'),
             verbatimTextOutput('runTime')             
#             tableOutput('debug5')
             ),
    tabPanel("Uncertainty",
             h5('Empirical 95% uncertainty intervals'),
             h4('Results after 5 years'),
             tableOutput('uncertaintyTable5'),
             br(),
             h4('Results after 10 years'),
             tableOutput('uncertaintyTable10'),
             br(),
             h4('Results after 20 years'),
             tableOutput('uncertaintyTable20')
             ),
    'Support Pages',
    tabPanel('Adjust treated survival data',
             h4('Coming soon: use this utility to calculate baseline survival from treated survival')
    ),
    tabPanel('Run the model locally',
             h4('Coming soon: follow these instructions to run the model on your own computer'),
             p('This alternative to running the model on the web may help speed your computation time.')
    )
  
  ) # end navlistPanel
)) # end fluidPage and shinyUI


