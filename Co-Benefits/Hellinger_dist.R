##############################################################################################
###################### This function calculates the Hellinger Distance  for     #################
###################### functional data                                          ##############
##############################################################################################


### Description
# Return a matrix of Hellinger distance between two or more functions 

### Usage
# dist.Hellinger(x,ncol)

### Arguments
# x       Matrix of positive values or heights of discrete or discretized functions.
#         Each column corresponds to a function.
# nc      number of functions or curves.

### Value
# dist.Hellinger returns an object of class "dist" containing Hellinger distances.


dist.Hellinger=function(x,nc){
  a=combn(1:nc,2)
  dist=matrix(rep(NA,times=ncol(x)^2),ncol=nc,byrow=T)
  for(i in 1:ncol(a)){
    dist[a[1,i],a[2,i]]=sqrt(sum((sqrt(x[,a[1,i]])-sqrt(x[,a[2,i]]))^2))  
    dist[a[2,i],a[1,i]]=sqrt(sum((sqrt(x[,a[1,i]])-sqrt(x[,a[2,i]]))^2))
  }
  dist=as.dist(dist)
  return(dist)
}

# A simple example
x <- matrix(rbeta(100,0.5,1.5), nrow = 5)
# Using Euclidean distance
dist(x)
# Using Hellinger distance
y=t(x)
dist.Hellinger(y,ncol(y))

