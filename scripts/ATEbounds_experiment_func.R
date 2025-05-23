## experiment::ATEbounds
function (formula, data = parent.frame(), maxY = NULL, minY = NULL, 
          alpha = 0.05, n.reps = 0, strata = NULL, ratio = NULL, survey = NULL, 
          ...) 
{
  call <- match.call()
  tm <- terms(formula)
  attr(tm, "intercept") <- 0
  mf <- model.frame(tm, data = data, na.action = "na.pass")
  D <- model.matrix(tm, data = mf)
  M <- ncol(D)
  if (max(D) > 1 || min(D) < 0) 
    stop("the treatment variable should be a factor variable.")
  Y <- model.response(mf)
  if (is.null(maxY)) 
    maxY <- max(Y, na.rm = TRUE)
  if (is.null(minY)) 
    minY <- min(Y, na.rm = TRUE)
  if (!is.null(call$survey)) 
    survey <- eval(call$survey, data)
  else survey <- rep(1, length(Y))
  if (!is.null(call$strata)) {
    strata <- eval(call$strata, data)
    res <- boundsAggComp(cbind(Y, strata, D), rep(1, length(Y)), 
                         maxY, minY, alpha = alpha, ratio = ratio, survey = survey)
  }
  else {
    res <- boundsComp(cbind(Y, D), rep(1, length(Y)), maxY, 
                      minY, alpha = alpha, survey = survey)
  }
  if (n.reps > 0) {
    if (!is.null(call$strata)) {
      breps <- boot(data = cbind(Y, strata, D), statistic = boundsAggComp, 
                    R = n.reps, maxY = maxY, minY = minY, alpha = NULL, 
                    survey = survey)$t
      res$bmethod.ci <- res$bonf.ci <- matrix(NA, ncol = 2, 
                                              nrow = choose(M, 2))
      counter <- 1
      for (i in 1:(M - 1)) for (j in (i + 1):M) {
        tmp <- boundsCI(breps[, counter], breps[, counter + 
                                                  1], res$bounds[(counter + 1)/2, 1], res$bounds[(counter + 
                                                                                                    1)/2, 2], alpha)
        res$bmethod.ci[(counter + 1)/2, ] <- tmp$bmethod
        res$bonf.ci[(counter + 1)/2, ] <- tmp$bonferroni
        counter <- counter + 2
      }
    }
    else {
      breps <- boot(data = cbind(Y, D), statistic = boundsComp, 
                    R = n.reps, maxY = maxY, minY = minY, alpha = NULL, 
                    survey = survey)$t
      res$bmethod.ci.Y <- matrix(NA, ncol = 2, nrow = M)
      res$bmethod.ci <- matrix(NA, ncol = 2, nrow = choose(M, 
                                                           2))
      for (i in 1:M) {
        tmp <- boundsCI(breps[, (i - 1) * 2 + 1], breps[, 
                                                        i * 2], res$bounds.Y[i, 1], res$bounds.Y[i, 
                                                                                                 2], alpha)
        res$bmethod.ci.Y[i, ] <- tmp$bmethod
        res$bonf.ci.Y[i, ] <- tmp$bonferroni
      }
      counter <- 1
      for (i in 1:(M - 1)) for (j in (i + 1):M) {
        tmp <- boundsCI(breps[, 2 * M + counter], breps[, 
                                                        2 * M + counter + 1], res$bounds[(counter + 
                                                                                            1)/2, 1], res$bounds[(counter + 1)/2, 2], alpha)
        res$bmethod.ci[(counter + 1)/2, ] <- tmp$bmethod
        res$bonf.ci[(counter + 1)/2, ] <- tmp$bonferroni
        counter <- counter + 2
      }
    }
  }
  tmp <- NULL
  for (i in 1:(M - 1)) for (j in (i + 1):M) tmp <- c(tmp, paste(colnames(D)[i], 
                                                                "-", colnames(D)[j]))
  if (is.null(call$strata)) {
    rownames(res$bounds.Y) <- rownames(res$bonf.ci.Y) <- colnames(D)
    rownames(res$bounds) <- rownames(res$bonf.ci) <- tmp
    colnames(res$bounds) <- colnames(res$bounds.Y) <- c("lower", 
                                                        "upper")
    colnames(res$bonf.ci) <- colnames(res$bonf.ci.Y) <- c(paste("lower ", 
                                                                alpha/2, "%CI", sep = ""), paste("upper ", 1 - alpha/2, 
                                                                                                 "%CI", sep = ""))
    if (n.reps > 0) {
      rownames(res$bmethod.ci.Y) <- colnames(D)
      rownames(res$bmethod.ci) <- tmp
      colnames(res$bmethod.ci) <- colnames(res$bmethod.ci.Y) <- c(paste("lower ", 
                                                                        alpha/2, "%CI", sep = ""), paste("upper ", 1 - 
                                                                                                           alpha/2, "%CI", sep = ""))
    }
  }
  else {
    rownames(res$bounds) <- tmp
    colnames(res$bounds) <- c("lower", "upper")
    if (n.reps > 0) {
      rownames(res$bmethod.ci) <- rownames(res$bonf.ci) <- tmp
      colnames(res$bmethod.ci) <- colnames(res$bonf.ci) <- c(paste("lower ", 
                                                                   alpha/2, "%CI", sep = ""), paste("upper ", 1 - 
                                                                                                      alpha/2, "%CI", sep = ""))
    }
  }
  res$Y <- Y
  res$D <- D
  res$call <- call
  class(res) <- "ATEbounds"
  return(res)
}