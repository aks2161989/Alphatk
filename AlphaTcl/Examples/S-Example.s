## -*-S-*-
 # ==========================================================================
 # S-Example.s
 # 
 # Distributed as an example of Alpha's S+/R mode.
 # 
 # ==========================================================================
 ##

## 
 # ==========================================================================
 # FILE: "ps03.1.s"
 #                                          created: 11/23/1998 {09:30:54 pm} 
 #                                      last update: 03/06/2000 {06:31:43 PM}
 # Description: 
 #
 # S-Plus source code necessary to answer question 1 of problem set 3. 
 # Summary statistics can be obtained by running source file
 # ps03.1-summary.s
 #
 # This file also uses the S-Plus functions "latab.reg1()" and
 # "print.reg.out()" that will print regression output in LaTeX format.
 #
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 1998-2000 Craig Barton Upright
 # All rights reserved.
 # 
 # ==========================================================================
 ##

### Preliminaries

# reading in and transforming data, attaching dataframe data01

data03.1	<-  read.table("../data/ship.dat")

# correcting a misnamed factor value in data03.1$year

for (i in 1:length(data03.1$year)){
    data03.1$year <- as.vector(data03.1$year)
    if(data03.1$year[i] == "1965-70") (data03.1$year[i] <- c("1965-69"))
}

data03.1$year	<-  factor(data03.1$year)

# creating a linear variable for "year," using midpoint of construction year

year.linear	<-  as.vector(data03.1$year)

for (i in 1:length(year.linear)){

    if(year.linear[i] == "1960-64") (year.linear[i] <- 1962)
    if(year.linear[i] == "1965-69") (year.linear[i] <- 1967)	
    if(year.linear[i] == "1970-74") (year.linear[i] <- 1972)
    if(year.linear[i] == "1975-79") (year.linear[i] <- 1977)
}

data03.1$year.linear   <-  as.numeric(year.linear); rm(year.linear)	

options(contrasts = c("contr.treatment", "contr.treatment") )

attach(data03.1)

out3.11 <-  glm(incidents ~ type1 + year + offset(log(months)),
                x = T, y = T, poisson)
out3.12 <-  glm(incidents ~ type1 + year.linear + offset(log(months)), 
                x = T, y = T, poisson)
out3.13	<-  glm(incidents ~ type1 + year.linear + year.linear^2 
                + offset(log(months)), poisson, x = T, y = T)
out3.14 <-  glm(incidents ~ type1 * year.linear + offset(log(months)), 
                x = T, y = T, poisson)

### Figures
		
# generating a postcript file with residual diagnostics of model out3.11

postscript(file = "../figures/ps03-QQPLOT.ps", horizontal = F, height = 4)

	par(mfrow = c(1,2))
        plot(out3.11$y, resid(out3.11), 
                xlab = "observed values", ylab = "deviance residuals")
        abline(h = 2, lty = 2)
        qqnorm(resid(out3.11), ylab = "deviance residuals")
        qqline(resid(out3.11), lty = 2)
        dev.off()

detach()


### Summary Output

# creating a file with summary statistics, latex tables

source("/u/cupright/S-Plus_library-cbu/print.reg.out.s")

source("/u/cupright/S-Plus_library-cbu/latab.reg1.s")

d 	<- date()

sink	("ps03.1.txt")

cat("# ps03.1.txt \n")
cat("# \n")
cat("# Summary statistics of regression objects produced by ps03.1.s \n")
cat("# source(\"ps03.1-summary.s\") \n")
cat("# \n")
cat("# Craig Barton Upright\n")
cat("#", substring(d,9,10), substring(d,4,7), ",", substring(d,25,28), "\n\n")

print.reg.out(out3.11, name = "out3.11", 
                alt = "additive log-linear model")
print.reg.out(out3.12, name = "out3.12", 
                alt = "treating year as linear effect")
print.reg.out(out3.13, name = "out3.13", 
                alt = "treating year as linear with square effect")
print.reg.out(out3.14, name = "out3.14", alt = "interaction model")

attach(data03.1)

print(anova(out3.14, test = "F"))

detach()

cat("\n\nDeviance residuals for model out3.11: \n\n")
print(round(resid(out3.11),2)); cat("\n\n")

cat("sum of deviance residuals for model out3.11:", 
        round(sum(resid(out3.11)^2),2), "\n")
cat("residual deviance of model out3.11:         ", 
        round(out3.11$dev, 2), "\n\n")

latab.reg1(out3.11, dev = T)
latab.reg1(out3.13, dev = T)

sink()
rm(out3.11, out3.12, out3.13, out3.14)
rm(d) 
cat("\nGenerated ascii file ps03.1.txt \n\n")


# .