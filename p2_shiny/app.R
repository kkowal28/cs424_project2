######################################################
# CS 424 | Project 2
# Kevin Kowalski - kkowal28
# Samuel Kajah - skajah2
# Vijay Vemu - vvemu3
######################################################
#
# < insert project info and notes here >
#
######################################################

# import libraries
library(comprehenr)
library(dplyr)
library(ggplot2)
library(hashmap)
library(leaflet)
library(leaflet.extras)
library(lubridate)
library(magrittr)
library(readr)
library(shiny)
library(shinydashboard)
library(stringr)

# retrieve helper functions
source("helper.R")

# read in the processed data
atlantic_data <- readRDS(file = "atlantic_data.rds")
pacific_data <- readRDS(file = "pacific_data.rds")

########################## DATA NEEDED FOR PLOTTING #####################################
########################## DATA NEEDED FOR PLOTTING #####################################


atlantic_since2005 = get_storms_since(atlantic_data, 2005)

# for the select input in UI, not all are showing; explore later
atlantic_storm_days = c("", get_all_storm_days(atlantic_since2005))

atlantic_top10 = get_top_10_storms(atlantic_data)

pacific_top10 = get_top_10_storms(pacific_data)

atlantic_names_since_2005 = get_storm_names(atlantic_since2005)

atlantic_top10_names = get_storm_names(atlantic_top10)
pacific_top10_names = get_storm_names(pacific_top10)


name_to_ocean_map = hashmap('', '')

# when showing both names, need to be able to differentiate between atlantic and pacific
# make a mapping of name to ocean
for (storm_data in pacific_data){
  storm_name = storm_data$Storm_Name[1] # just need the first 1
  name_to_ocean_map[[storm_name]] = "PACIFIC"
}

for (storm_data in atlantic_data){
  storm_name = storm_data$Storm_Name[1]
  name_to_ocean_map[[storm_name]] = "ATLANTIC"
}


combined_data = c(atlantic_data, pacific_data)
all_storm_names = get_storm_names(combined_data)
combined_top10_names = get_storm_names(get_top_10_storms(combined_data))

post2005_combined_data <- get_storms_since(combined_data, 2005)
binded_rows <- bind_rows(post2005_combined_data, .id="df")


days_and_years = get_all_days_and_years(combined_data)

pacific_month_data = get_month_data(pacific_data)
atlantic_month_data = get_month_data(atlantic_data)


########################## DASHBOARD #####################################
########################## DASHBOARD #####################################

ui = dashboardPage(
  
  dashboardHeader(title = "Best Track Data (HURDAT2)", titleWidth = 300),
  
  dashboardSidebar(disable = FALSE, collapsed = FALSE, width = 250,
                   sidebarMenu(
                     # add space to sidebar
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL)),
                   
                   # about button
                   actionButton("about_info", "About", width = 220),
                   
                   sidebarMenu(
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("Make Selections:", tabName = "cheapBlankSpace", icon = NULL)),
                   
                   # list of inputs in sidebar
                   tabsetPanel(id = "inputs_tab", type = "tabs",
                               tabPanel(value = "date_inputs", title = "Time", 
                                        div(style='height:300px; width:250px;', 
                                            sidebarMenu(
                                              menuItem("", tabName = "cheapBlankSpace", icon = NULL)),
                                            selectInput(inputId = "years", label = "Select a Year", choices = days_and_years$years),
                                            sidebarMenu(
                                              menuItem("", tabName = "cheapBlankSpace", icon = NULL)),
                                            selectInput(inputId = "days", label = "Select a Date", choices = c("", days_and_years$days))
                                        )
                               ),
                               tabPanel(value = "data_inputs", title = "Values", 
                                        div(style='height:300px; width:250px;',
                                            radioButtons(inputId = "made_land", label = "Made Landfall?", choices = c("True", "False"), inline = TRUE, selected = character(0)),
                                            sliderInput(inputId = "max_wind_speed", label = "Wind Speed Range (in knots)", min = 0, max = 185, value = c(0, 185)),
                                            sliderInput(inputId = "min_pressure", label = "Pressure Range (in millibars)", min = 0, max = 1024, value = c(0, 1024))
                                        )
                               ),
                               tabPanel(value = "sort_inputs", title = "Filter", 
                                        div(style='height:300px; width:250px;',
                                            sidebarMenu(
                                              menuItem("", tabName = "cheapBlankSpace", icon = NULL)),
                                            actionButton(inputId = "show_all_names_button", label = "Show All Since 2005", width = 220),
                                            actionButton(inputId = "show_top10_names_button", label = "Show Top 10", width = 220),
                                            actionButton(inputId = "check_all_button", label = "Select All", width = 220),
                                            actionButton(inputId = "uncheck_all_button", label = "Deselect All", width = 220),
                                            sidebarMenu(
                                              menuItem("", tabName = "cheapBlankSpace", icon = NULL)),
                                            selectInput(inputId = "storm_order", label = "Order by",
                                                        choices = c("", "Alphabetically", "Chronologically", "Max Speed", "Min Pressure"))
                                        )
                               )
                   ), # end tabsetPanel
                   
                   sidebarMenu(
                     menuItem("", tabName = "cheapBlankSpace", icon = NULL),
                     menuItem("Hurricane Lists:", tabName = "cheapBlankSpace", icon = NULL)),
                   
                   # list of hurricanes in sidebar
                   tabsetPanel(id = "storm_tab", type = "tabs",
                               tabPanel(value = "atlantic", title = "Atlantic", 
                                        div(style='height:500px; width:250px; overflow: scroll',
                                            checkboxGroupInput(inputId = "atlantic_storm_names", 
                                                               choices =c(""), label = ""
                                            )
                                        )
                               ),
                               tabPanel(value = "pacific", title = "Pacific", 
                                        div(style='height:500px; width:250px; overflow: scroll', 
                                            checkboxGroupInput(inputId = "pacific_storm_names", 
                                                               choices =c(""), label = ""
                                            )
                                        )
                               ),
                               tabPanel(value = "combined", title = "Combined", 
                                        div(style='height:500px; width:250px; overflow: scroll',
                                            checkboxGroupInput(inputId = "combined_storm_names", 
                                                               choices =c(""), label = ""
                                            )
                                        )
                               )
                   ) # end tabsetPanel
  ), # end sidebarMenu
  
  dashboardBody(
    fluidRow(
      column(5, 
             box(title = "Line Graphs of Speed & Pressure", width = NULL, status = "info", 
              tabsetPanel(
                tabPanel("Maximum Speed", plotOutput("max_wind_speed_graph")),
                tabPanel("Minimum Pressure", plotOutput("min_pressure_graph"))
              )
             )
      ),
      column(2, 
             box(title = "Number of Hurricanes/Category in Given Year", width = NULL, status = "info",
                 plotOutput("category_counts")
             )
      ),
      column(5, 
             box(title = "Number of Hurricanes/Year since 2005", solidHeader = FALSE, 
                 width = NULL, status = "info", style = "font-size:150%",
                 plotOutput("overview")
             )
      )
    ),
    fluidRow(
      
      column(5, 
             box(title = "Map of Atlantic Hurricanes", width = NULL, height = 750, status = "info",
                 leafletOutput(outputId = "atlantic_map", height = 675)
             )
      ),
      column(2, 
             box(title = "Monthly Hurricanes Over All Years", width = NULL, status = "info", style = "font-size:150%",
                 plotOutput("monthly_counts", height = 675)
             )
      ),
      column(5, 
             box(title = "Map of Pacific Hurricanes", width = NULL, height = 750, status = "info",
                 leafletOutput(outputId = "pacific_map", height = 675)
             )
      )
      
    ) # end fluidRow
  ) # end dashboardBody
)# end dashboardPage


server = function(input, output, session) {
  
  shown_pacific_names = reactiveVal() # keep track of which names are currently being displayed
  shown_atlantic_names = reactiveVal() # keep track of which names are currently being displayed
  shown_combined_names = reactiveVal() # keep track of which names are currently being displayed
  
  # should update the combined one
  combined2018 = get_storms_by_year(combined_data, 2018)
  combined_names = get_storm_names(combined2018)
  
  atlantic2018 = get_storms_by_year(atlantic_data, 2018)
  atlantic_names = get_storm_names(atlantic2018)
  
  pacific2018 = get_storms_by_year(pacific_data, 2018)
  pacific_names = get_storm_names(pacific2018)
  
  shown_pacific_names(pacific_names)
  shown_atlantic_names(atlantic_names)
  shown_combined_names(combined_names)
  
  # initially, only atlantic is populated; do the rest
  updateCheckboxGroupInput(session, "pacific_storm_names", choices = pacific_names, selected = pacific_names)
  updateCheckboxGroupInput(session, "combined_storm_names", choices = combined_names, selected = combined_names)
  
  observeEvent(input$about_info, {
    showModal(
      modalDialog(
        HTML(read_file("about.html")),
        easyClose = TRUE
      )
    ) # end showModal
  }) # end about info 
  
  
  output$monthly_counts = renderPlot({
    
   graph_month_data(pacific_month_data, atlantic_month_data)
   
  })
  
  # Show all storms; must check which tab is currently shown
  observeEvent(input$show_all_names_button, {
    if (input$storm_tab == "pacific"){
      names_to_show = get_storm_names(pacific_data)
      # don't auto select because there's a lot of names
      updateCheckboxGroupInput(session, "pacific_storm_names", choices = names_to_show)
      shown_pacific_names(names_to_show) # update the shown names
    } else if (input$storm_tab == "atlantic"){
      names_to_show = get_storm_names(atlantic_data)
      # don't auto select because there's a lot of names
      updateCheckboxGroupInput(session, "atlantic_storm_names", choices = names_to_show)
      shown_atlantic_names(names_to_show)
    } else {  # must be combined tab
      # don't auto select because there's a lot names
      updateCheckboxGroupInput(session, "combined_storm_names", choices = all_storm_names)
      shown_combined_names(all_storm_names)
    }
  })
  
  # Show only top 10 storms; must check which tab is currently shown
  observeEvent(input$show_top10_names_button, {
    if (input$storm_tab == "pacific"){
      # update and select all
      updateCheckboxGroupInput(session, "pacific_storm_names", choices = pacific_top10_names, selected = pacific_top10_names)
      shown_pacific_names(pacific_top10_names) # update the shown names
      
    } else if (input$storm_tab == "atlantic"){
      # update and select all
      updateCheckboxGroupInput(session, "atlantic_storm_names", choices = atlantic_top10_names, selected = atlantic_top10_names)
      shown_atlantic_names(atlantic_top10_names) # update the shown names
      
    } else {  # must be combined tab
      # update and select all
      updateCheckboxGroupInput(session, "combined_storm_names", choices = combined_top10_names, selected = combined_top10_names)
      shown_combined_names(combined_top10_names) # update the shown names
    }
  })
  
  # Check all the options currently shown; must check which tab is currently shown 
  observeEvent(input$check_all_button, {
    if (input$storm_tab == "pacific"){
      updateCheckboxGroupInput(session, "pacific_storm_names", 
                               choices = shown_pacific_names(), selected = shown_pacific_names())
    } else if (input$storm_tab == "atlantic"){
      updateCheckboxGroupInput(session, "atlantic_storm_names", 
                               choices = shown_atlantic_names(), selected = shown_atlantic_names())
    } else { # must be combined tab
      updateCheckboxGroupInput(session, "combined_storm_names", 
                               choices = shown_combined_names(), selected = shown_combined_names())
    }
    
  })
  
  # Uncheck all the options currently shown; must check which tab is currently shown
  observeEvent(input$uncheck_all_button, {
    if (input$storm_tab == "pacific"){
      updateCheckboxGroupInput(session, "pacific_storm_names", 
                               choices = shown_pacific_names())
      output$pacific_map = renderLeaflet({leaflet() %>% addProviderTiles(providers$Esri.WorldStreetMap)}) # show empty map
      
    } else if (input$storm_tab == "atlantic"){
      updateCheckboxGroupInput(session, "atlantic_storm_names", 
                               choices = shown_atlantic_names())
      output$atlantic_map = renderLeaflet({leaflet() %>% addProviderTiles(providers$Esri.WorldStreetMap)}) # show empty map
      
    } else { # must be combined tab
      updateCheckboxGroupInput(session, "combined_storm_names", 
                               choices = shown_combined_names())
      output$atlantic_map = renderLeaflet({leaflet() %>% addProviderTiles(providers$Esri.WorldStreetMap)}) # show empty map
      output$pacific_map = renderLeaflet({leaflet() %>% addProviderTiles(providers$Esri.WorldStreetMap)}) # show empty map
    }
    
  })
  
  # Order by option; must check which tab is currently shown to rearrange the correct names
  observeEvent(input$storm_order, {
    order_by = input$storm_order
    if (order_by != ""){
      
      tab = input$storm_tab
      checkbox_group_name = 
        if (tab == "pacific") 
          "pacific_storm_names" 
      else if (tab == "atlantic") 
        "atlantic_storm_names" 
      else 
        "combined_storm_names"
      
      data = 
        if (tab == "pacific") 
          pacific_data 
      else if (tab == "atlantic") 
        atlantic_data 
      else combined_data
      
      # keep track of selected since we'll be rearranging the list
      selected_names = 
        if (tab == "pacific") 
          input$pacific_storm_names 
      else if (tab == "atlantic") 
        input$atlantic_storm_names 
      else 
        input$combined_storm_names
      
      shown_names = 
        if (tab == "pacific")
          shown_pacific_names()
      else if (tab == "atlantic")
        shown_atlantic_names()
      else
        shown_combined_names()
      
      if (order_by == "Alphabetically"){
        updateCheckboxGroupInput(session, checkbox_group_name, 
                                 choices = get_storm_names_alphabetically(
                                   get_storms_by_name(data , shown_names)
                                 ),
                                 selected = selected_names
        )
      } else if (order_by == "Chronologically"){
        updateCheckboxGroupInput(session, checkbox_group_name, 
                                 choices = get_storm_names_chronologically(
                                   get_storms_by_name(data , shown_names)
                                 ),
                                 selected = selected_names
        )
      } else if (order_by == "Max Speed"){
        updateCheckboxGroupInput(session, checkbox_group_name, 
                                 choices = get_storm_names_max_speed(
                                   get_storms_by_name(data , shown_names)
                                 ),
                                 selected = selected_names
        )
      } else if (order_by == "Min Pressure"){
        updateCheckboxGroupInput(session, checkbox_group_name, 
                                 choices = get_storm_names_min_pressure(
                                   get_storms_by_name(data , shown_names)
                                 ),
                                 selected = selected_names
        )
      }
    } # end if
    
  }) # no need to update shown names because they are the same; just changing the order
  
  
  # filter hurricanes if they made land; must check which tab is currently shown
  observeEvent(input$made_land, {
    tab = input$storm_tab 
    checkbox_group_name = 
      if (tab == "pacific") 
        "pacific_storm_names" 
    else if (tab == "atlantic") 
      "atlantic_storm_names" 
    else 
      "combined_storm_names"
    
    data = if (tab == "pacific") 
      pacific_data 
    else if (tab == "atlantic") 
      atlantic_data 
    else 
      combined_data
    
    shown_names = 
      if (tab == "pacific")
        shown_pacific_names()
    else if (tab == "atlantic")
      shown_atlantic_names()
    else
      shown_combined_names()
    
    if (input$made_land == "True"){
      made_land_storms = get_storms_landfall(get_storms_by_name(data ,shown_names))
      made_land_names = get_storm_names(made_land_storms)
      
      updateCheckboxGroupInput(session, checkbox_group_name, choices = shown_names, selected = made_land_names)
    } else if (input$made_land == "False"){
      made_no_land_storms = get_storms_no_landfall(get_storms_by_name(data ,shown_names))
      made_no_land_names = get_storm_names(made_no_land_storms)
      
      updateCheckboxGroupInput(session, checkbox_group_name, choices = shown_names, selected = made_no_land_names)
    }
  })
  
  
  # filter storms within a given range of max wind speed; must check which tab is currently shown
  observeEvent(input$max_wind_speed,  {
    # print("In max speed")
    tab = input$storm_tab 
    checkbox_group_name = 
      if (tab == "pacific") 
        "pacific_storm_names" 
    else if (tab == "atlantic") 
      "atlantic_storm_names" 
    else 
      "combined_storm_names"
    
    data = if (tab == "pacific") 
      pacific_data 
    else if (tab == "atlantic") 
      atlantic_data 
    else 
      combined_data
    
    shown_names = 
      if (tab == "pacific")
        shown_pacific_names()
    else if (tab == "atlantic")
      shown_atlantic_names()
    else
      shown_combined_names()
    
    low = input$max_wind_speed[1]
    high = input$max_wind_speed[2]
    
    storms_within_speed_range = get_storm_names_max_speed(get_storms_by_name(data, shown_names), low, high)
    
    updateCheckboxGroupInput(session, checkbox_group_name, choices = shown_names, selected = storms_within_speed_range)
    
    output$monthly_counts = renderPlot({
      pacific_months = get_month_data_max_wind_speed(pacific_data, low, high)
      atlantic_months = get_month_data_max_wind_speed(atlantic_data, low, high)
      
      graph_month_data(pacific_months, atlantic_months)
    })
    
  })
  
  # filter storms within a given range of min pressure; must check which tab is currently shown
  observeEvent(input$min_pressure,  {
    # print("In min pressure")
    tab = input$storm_tab 
    checkbox_group_name = 
      if (tab == "pacific") 
        "pacific_storm_names" 
    else if (tab == "atlantic") 
      "atlantic_storm_names" 
    else 
      "combined_storm_names"
    
    data = 
      if (tab == "pacific") 
        pacific_data 
    else if (tab == "atlantic") 
      atlantic_data 
    else 
      combined_data
    
    shown_names = 
      if (tab == "pacific")
        shown_pacific_names()
    else if (tab == "atlantic")
      shown_atlantic_names()
    else
      shown_combined_names()
    
    low = input$min_pressure[1]
    high = input$min_pressure[2]
    
    
    storms_within_pressure_range = get_storm_names_min_pressure(get_storms_by_name(data, shown_names), low, high)
    
    updateCheckboxGroupInput(session, checkbox_group_name, choices = shown_names, selected = storms_within_pressure_range)
    
    output$monthly_counts = renderPlot({
      pacific_months = get_month_data_min_pressure(pacific_data, low, high)
      atlantic_months = get_month_data_min_pressure(atlantic_data, low, high)
      
      graph_month_data(pacific_months, atlantic_months)
    })
    
  })
  
  # when year chosen, only shown storms from that year
  # must check which tab is currently shown to show the correct names
  observeEvent(input$years, {
    tab = input$storm_tab
    checkbox_group_name = 
      if (tab == "pacific") 
        "pacific_storm_names" 
    else if (tab == "atlantic") 
      "atlantic_storm_names" 
    else 
      "combined_storm_names"
    
    year_storms = 
      if (tab == "pacific") 
        get_storms_by_year(pacific_data, input$years) 
    else if (tab == "atlantic")
      get_storms_by_year(atlantic_data, input$years)
    else
      get_storms_by_year(combined_data, input$years)
    
    names = get_storm_names(year_storms)
    
    # update shown names
    if (tab == "pacific")
      shown_pacific_names(names)
    else if (tab == "atlantic")
      shown_atlantic_names(names)
    else
      shown_combined_names(names)
    
    # get the values
    shown_names = 
      if (tab == "pacific")
        shown_pacific_names()
    else if (tab == "atlantic")
      shown_atlantic_names()
    else
      shown_combined_names()
    
    # autocheck all
    updateCheckboxGroupInput(session, checkbox_group_name, 
                             choices = shown_names, selected = shown_names)
    
    
    # update the days to only show for the current year 
    updateSelectInput(session, "days", 
                      choices = c("", to_vec(
                        for (date in days_and_years$days) if (endsWith(date, as.character(input$years))) date)
                      )
    )
    
    # have to do for both of them because the wind and pressure graphs show both oceans regardless of what tab
    atlantic_year = get_storms_by_year(atlantic_data, input$years)
    pacific_year = get_storms_by_year(pacific_data, input$years)
    
    # user sees all years; pacific doesn't go as far back as atlantic so check
    if (length(pacific_year) == 0) { # can only show atlantic
      atlantic_speed_pressure_table = get_storm_names_max_speed_min_pressure_table(atlantic_year)
      
      # show min pressure graph for atlantic only
      output$min_pressure_graph = renderPlot({
        ggplot(data = atlantic_speed_pressure_table, aes(x = Timestamp, y = MinPressure)) +
          geom_line() + geom_point() + 
          labs(x = "Day", y = "Pressure (millibars)", title = paste("Minimum Pressures in ", input$years, "(Atlantic)")) + 
          theme(axis.text.x = element_text(size = 14), axis.text.y = element_text(size = 14), 
                axis.title.x = element_text(size = 16), axis.title.y = element_text(size = 16),
                plot.title = element_text(size = 18))
      })
      
      # show max speed graph for atlantic only
      output$max_wind_speed_graph = renderPlot({
        ggplot(data = atlantic_speed_pressure_table, aes(x = Timestamp, y = TopSpeed)) +
          geom_line() + geom_point() + 
          labs(x = "Day", y = "Wind Speed (knots)", title = paste("Maximum Wind Speeds in ", input$years, "(Atlantic)")) + 
          theme(axis.text.x = element_text(size = 14), axis.text.y = element_text(size = 14), 
                axis.title.x = element_text(size = 16), axis.title.y = element_text(size = 16),
                plot.title = element_text(size = 18))
      })
      
    } else { # both can be displayed
      atlantic_speed_pressure_table = get_storm_names_max_speed_min_pressure_table(atlantic_year) %>%  mutate(ocean = "ATLANTIC")
      pacific_speed_pressure_table = get_storm_names_max_speed_min_pressure_table(pacific_year) %>%  mutate(ocean = "PACIFIC")
      
      combined_table = rbind(atlantic_speed_pressure_table, pacific_speed_pressure_table)
      
      # show max speed graph for both oceans
      output$max_wind_speed_graph = renderPlot({
        ggplot(data = combined_table, aes(x = Timestamp, y = TopSpeed)) +
          geom_line(aes(color = ocean)) + geom_point(aes(color = ocean)) + 
          labs(x = "Day", y = "Wind Speed (knots)", title = paste("Maximum Wind Speeds in ", input$years)) + 
          theme(axis.text.x = element_text(size = 14), axis.text.y = element_text(size = 14), 
                axis.title.x = element_text(size = 16), axis.title.y = element_text(size = 16),
                plot.title = element_text(size = 18))
      })
      
      # show min pressure graph for both oceans
      output$min_pressure_graph = renderPlot({
        ggplot(data = combined_table, aes(x = Timestamp, y = MinPressure)) +
          geom_line(aes(color = ocean)) + geom_point(aes(color = ocean)) + 
          labs(x = "Day", y = "Pressure (millibars)", title = paste("Minimum Pressures in ", input$years)) + 
          theme(axis.text.x = element_text(size = 14), axis.text.y = element_text(size = 14), 
                axis.title.x = element_text(size = 16), axis.title.y = element_text(size = 16),
                plot.title = element_text(size = 18))
      })
    }
    
    output$category_counts = renderPlot({
      graph_category_counts(pacific_year, atlantic_year, input$years) 
    })
  })
  
  # when day chosen, only shown storms from that day
  # must check which tab is currently shown to show the correct names
  observeEvent(input$days, {
    if (input$days != ""){
      tab = input$storm_tab
      checkbox_group_name = 
        if (tab == "pacific") 
          "pacific_storm_names" 
      else if (tab == "atlantic") 
        "atlantic_storm_names" 
      else "combined_storm_names"
      
      day_storms = 
        if (tab == "pacific") 
          get_storms_by_day(pacific_data, input$days) 
      else if (tab == "atlantic")
        get_storms_by_day(atlantic_data, input$days)
      else
        get_storms_by_day(combined_data, input$days)
      
      names = get_storm_names(day_storms)
      
      # update shown names
      if (tab == "pacific")
        shown_pacific_names(names)
      else if (tab == "atlantic")
        shown_atlantic_names(names)
      else
        shown_combined_names(names)
      
      # get the values
      shown_names = 
        if (tab == "pacific")
          shown_pacific_names()
      else if (tab == "atlantic")
        shown_atlantic_names()
      else
        shown_combined_names()
      
      # autocheck all
      updateCheckboxGroupInput(session, checkbox_group_name, 
                               choices = shown_names, selected = shown_names)
    }
  })
  
  observeEvent(input$pacific_storm_names, {
    # for some reason, last uncheck doesn't trigger observeEvent
    storms_to_plot = get_storms_by_name(pacific_data, input$pacific_storm_names)
    output$pacific_map = renderLeaflet({
      
      # check if pacific heatmap enabled
      if (!is.null(input$pac_heat) && input$pac_heat == "T")
          plot_storm_heatmap(storms_to_plot)
      else
          plot_multi_storm_path_by_size(storms_to_plot)
    })
  })
  
  observeEvent(input$atlantic_storm_names, {
    storms_to_plot = get_storms_by_name(atlantic_data, input$atlantic_storm_names)
    # print(input$atlantic_storm_names)
    # print("**********************************")
    output$atlantic_map = renderLeaflet({
      
      # check if atlantic heatmap enabled
      if (!is.null(input$atl_heat) && input$atl_heat == "T")
          plot_storm_heatmap(storms_to_plot)
      else
          plot_multi_storm_path_by_size(storms_to_plot)
    })
  })
  
  observeEvent(input$combined_storm_names, {
    # empty lists to store respective names
    pacific_storm_names = character() 
    atlantic_storm_names = character()
    for (storm_name in input$combined_storm_names){
      if (name_to_ocean_map[[storm_name]] == "PACIFIC"){
        pacific_storm_names = c(pacific_storm_names, storm_name)
      } else if (name_to_ocean_map[[storm_name]] == "ATLANTIC"){
        atlantic_storm_names = c(atlantic_storm_names, storm_name)
      }
    }
    
    if (length(pacific_storm_names) > 0){
      output$pacific_map = renderLeaflet({
        
        # check if pacific heatmap enabled
        if (!is.null(input$pac_heat) && input$pac_heat == "T")
            plot_storm_heatmap(get_storms_by_name(pacific_data, pacific_storm_names))
        else
            plot_multi_storm_path_by_size(get_storms_by_name(pacific_data, pacific_storm_names))

      })
    } else {
      output$pacific_map = renderLeaflet({leaflet() %>% addProviderTiles(providers$Esri.WorldStreetMap)}) # show empty map
    }
    
    if (length(atlantic_storm_names) > 0){
      output$atlantic_map = renderLeaflet({
        
        # check if atlantic heatmap enabled
        if (!is.null(input$atl_heat) && input$atl_heat == "T")
            plot_storm_heatmap(get_storms_by_name(atlantic_data, atlantic_storm_names))
        else
            plot_multi_storm_path_by_size(get_storms_by_name(atlantic_data, atlantic_storm_names))

      })
    } else {
      output$atlantic_map = renderLeaflet({leaflet() %>% addProviderTiles(providers$Esri.WorldStreetMap)}) # show empty map
    }
  })
  
  
  # overview graph
  output$overview <- renderPlot({
    ggplot(binded_rows, aes(x = year(binded_rows$Timestamp))) + 
      geom_bar(fill = "steelblue4") + 
      labs(x = "Year Occurred", y = "Number of Hurricances") + 
      scale_x_continuous(breaks=2005:2018) +
      theme(axis.text.x = element_text(size = 14, angle = 45), axis.text.y = element_text(size = 14), 
            axis.title.x = element_text(size = 16), axis.title.y = element_text(size = 16))
  }) 
}

shinyApp(ui=ui, server=server)

# for nonexistent names, check for order/filter (might leave alone)
# show empty map when filter shows nothing
# only update maps when necessary


