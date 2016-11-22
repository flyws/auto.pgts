
auto.pgts <- function(data, residual = F, pred = F){
  if("forecast" %in% rownames(installed.packages()) == FALSE) 
    {install.packages("forecast")}
  if("tseries" %in% rownames(installed.packages()) == FALSE) 
    {install.packages("tseries")}
  # load packages
  library(forecast)
  library(tseries)
  
  #choose between exploratory analysis or go directly to customization
  answer0 = readline("Do you have a custom model matrix? Y/N: ")
  if(answer0 == "N"){
    #display the data
    tsdisplay(data)
    # do the stationarity test
    cat(paste(" Augmented Dickey-Fuller Test(p-value < 0.05):",adf.test(data)$p.value),
        "\n",
        paste("KPSS Test for Level Stationarity(p-value > 0.05):",kpss.test(data)$p.value))
    answer1 = readline("Try differencing the data? Y/N: ")
    answer2 = "N"
    
    # find the right differencing value
  
    if(answer1 == "Y"){
      while(answer2 != "Y"){
        diffdata = readline("Please enter your diff data here: ")
        diffdata = eval(parse(text = diffdata))
        tsdisplay(diffdata)
        # display the stationarity test for evaluation
        cat(paste("Augmented Dickey-Fuller Test(p-value < 0.05):",adf.test(diffdata)$p.value),
            "\n",
            paste("KPSS Test for Level Stationarity(p-value > 0.05):",kpss.test(diffdata)$p.value))
        
        answer2 = readline("Do you like it now? Y/N: ")
        data = diffdata
      }
    }else{
      NULL
    }
    
    num_of_models = as.integer(readline("How many models you want to try: "))
    model_matrix = matrix(nrow = num_of_models, ncol = 6)
    for(i in 1:num_of_models){
      print(paste("input for model", i))
      cat("Please input two vectors that will be used as orders for model",i)
      num = scan(what = list("",""))
      model_matrix[i,1:3] = eval(parse(text = num[[1]]))
      model_matrix[i,4:6] = eval(parse(text = num[[2]]))
    }
    
    model = NULL
    criteria = readline("Specify the criterium you want to use: sigma2, aicc, ...: ")
    for(i in 1:num_of_models){
      model = c(model, Arima(data, order = model_matrix[i,1:3],
                       seasonal = model_matrix[i,4:6])[criteria][[1]])
    }
    
    print("Let's display the array of values that you selected:")
    print(model)
    print("...And the smallest among them is:")
    print(min(model))
    cat("which comes from the model", match(min(model),model),"\n")
    print("############################################")
    answer3 = readline("Store the model matrix for further use? Y/N: ")
    if(answer3 == "Y"){
      model_matrix <<- model_matrix
    }else{
      NULL
    }
  }else{
    #get the custom matrx name
    model_matrix = eval(parse(text = readline("What's the name? ")))
    model = NULL
    
    #calculate the criteria value
    criteria = readline("Specify the criterion you want to use: sigma2, aicc, ...: ")
    num_of_models = nrow(model_matrix)
    for(i in 1:num_of_models){
      model = c(model, Arima(data, order = model_matrix[i,1:3],
                             seasonal = model_matrix[i,4:6])[criteria][[1]])
    }
    
    print("############################################")
    print("Let's display the array of values that you selected:")
    print(model)
    print("...And the smallest among them is:")
    print(min(model))
    cat("which comes from the model", match(min(model),model), "\n")
    print("############################################")
  }
  
  # Save the best model in the global environment
  best_model <<- Arima(data, order = model_matrix[match(min(model),model),1:3],
                     seasonal = model_matrix[match(min(model),model),4:6])
  best_model_index <<- model_matrix[match(min(model),model),]
  
  # Perform the residual analysis
  if(residual == T){
    readline("displaying the time-series graph for residuals in best model. Press Enter to continue: ")
    resid = residuals(best_model)
    tsdisplay(resid)
    
    # do the stationarity test
    cat(paste(" Augmented Dickey-Fuller Test(p-value < 0.05):",adf.test(resid)$p.value),
        "\n",
        paste("KPSS Test for Level Stationarity(p-value > 0.05):",kpss.test(resid)$p.value))
    
    # Box Cox test
    readline("displaying Box test. Press Enter to continue: ")
    print("Keep in mind that the Ho: lag 1 corr = ... = lag k corr = 0")
    cat("\n")
    print("so we are hoping to p-value to be high to state independece")
    print(Box.test(resid))
    
    # Normality test
    readline("displaying qqplot. Press Enter to continue: ")
    qqnorm(resid)
    qqline(resid)
    print("We are hoping the majority of points lie on the 45 degree line.")
  }
  
  if(pred == T){
    cat("In total, we have", length(data), "observations in our data","\n")
    h = readline("Please enter a number to split the training and testing data: ")
    h = as.integer(h)
    rmsets(data, h)
    
    answer4 = readline("Want to see how well the fitted data is? Y/N: ")
    if(answer4 == "Y"){
      plot(data)
      FC = forecast(best_model, h = h)
      lines(fitted(FC), col = 2)
    }
  }
}

rmsets = function(tsdata, h,...)
{
  train.end=time(tsdata)[length(tsdata)-h]
  test.start=time(tsdata)[length(tsdata)-h+1]
  trainingset=window(tsdata,end=train.end)
  testingset = window(tsdata, start=test.start)
  training_model = Arima(trainingset, order = best_model_index[1:3],
                                    seasonal = best_model_index[4:6])
  modelforecast=forecast(training_model,h=h)
  print(accuracy(modelforecast,testingset)[2,"RMSE"])
  plot(modelforecast)
}
