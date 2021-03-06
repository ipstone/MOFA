
#######################################################
## Functions to perform imputation of missing values ##
#######################################################

#' @title Impute missing values from a fitted MOFA model
#' @name impute
#' @description This function uses the latent factors and the loadings inferred
#'  in order to impute missing values.
#' @param object a \code{\link{MOFAmodel}} object.
#' @param views character vector with the view names, or numeric vector with view indexes.
#' @param factors character vector with the factor names, or numeric vector with the factor indexes.
#' @param type type of prediction returned, either: 
#' \itemize{
#'  \item{\strong{response}:}{ gives the response vector, the mean for Gaussian and Poisson,
#'   and success probabilities for Bernoulli.}
#'  \item{\strong{link}:}{ gives the linear predictions.}
#'  \item{\strong{inRange}:}{ rounds the fitted values of integer-valued distributions
#'   (Poisson and Bernoulli) to the next integer.
#'  This is the default option.}
#' }
#' @return a \code{\link{MOFAmodel}} object with imputed data in the \code{ImputedData} slot
#' @details Matrix factorization models generate a denoised and condensed low-dimensional representation 
#' of the data which capture the main sources of heterogeneity of the data. 
#' Such representation can be used to do predictions via the equation \code{Y = WZ}. \cr
#' This method fills the \code{ImputedData} slot by replacing the missing values 
#' in the training data with the model predictions.\cr
#' For more details see the Methods section of the MOFA article.
#' @export
#' @examples 
#' # Load CLL data
#' filepath <- system.file("extdata", "CLL_model.hdf5", package = "MOFAdata")
#' MOFA_CLL <- loadModel(filepath)
#' # impute missing data in all views using all factors
#' MOFA_CLL <- impute(MOFA_CLL)
#' 
#' # Load scMT data
#' filepath <- system.file("extdata", "scMT_model.hdf5", package = "MOFAdata")
#' MOFA_scMT <- loadModel(filepath)
#' # impute missing data in the RNA view using Factor 1
#' MOFA_scMT <- impute(MOFA_scMT, views="RNA expression", factors="LF1")

impute <- function(object, views = "all", factors = "all", type = c("inRange","response", "link")) {
  
  # Get views  
  if (paste0(views,sep="",collapse="") =="all") { 
    views = viewNames(object)
  } else {
    stopifnot(all(views%in%viewNames(object)))
  }
  
  # Select imputation type  
  type = match.arg(type)
  
  # Do predictions
  predData <- predict(object, views=views, factors = factors, type = type)

  # replace NAs with predicted values
  imputedData <- getTrainData(object, views = views)
  imputedData <- lapply(names(imputedData), function(viewnm) {
      view <- imputedData[[viewnm]]
      non_observed <- which(is.na(view), arr.ind = TRUE)
      if(viewnm %in% names(predData)) view[non_observed] <- predData[[viewnm]][non_observed]
      view
  })

  # re- arrange list in accordance with other data slots in the model
  names(imputedData) <- views
  imputedData <- imputedData[viewNames(object)]
  names(imputedData) <- viewNames(object)

  # Save imputed data in the corresponding slot  
  ImputedData(object) <- imputedData
  
  return(object)
}
