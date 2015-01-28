###############################################################################
## Migrate Packages
###############################################################################

## Save Source List
temp = installed.packages()
installedpackages = subset(as.data.frame(temp),
    is.na(Priority))
installedpackages$Package <- as.character(installedpackages$Package)
save(installedpackages, file="~/Desktop/installed_packages.rda")


## Restore on Destination
load("~/Desktop/installed_packages.rda")

installedpackages <- subset(installedpackages[order(installedpackages$Built), ],
                            substr(as.character(Built), 1,1) == "3")

install.packages(installedpackages$Package)
