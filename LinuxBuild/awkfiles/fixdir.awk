BEGIN {
    FS = " "
}

###################################
#
# Remove these directives
#
##################################

/INT"/{
next
}

/OBJ"/{
next
}
 
##################################
#
# Replace: USE(.\DIRECTIVEES\COB.DIR)
#          USE($UXDIRS/COB.DIR)
#
##################################

/USE\(/ {
NEWLINE=$0
gsub(/\.\\DIRECTIVES\\/,"$DEFAULTDIR/",NEWLINE)
#gsub(/\\/,"/",NEWLINE)
print NEWLINE
next
}
##################################
#
# Replace: LISTPATH(D:\LISTINGS) -> LISTPATH($UXLISTINGS)
#
##################################

/LISTPATH\(/ {
NEWLINE=$0
gsub(/D:\\LISTINGS/,"$UXLISTINGS",NEWLINE)
print NEWLINE
next
}

##################################
#
# Replace: DB2 directives
#          BINDIR=C:\DIR\BINDIR -> BINDIR=$UXDBRMLIB
#          DB=DBNANE            -> DB=LINDBNAME
#          VERSION=WINSIT       -> VERSION=LINSIT
##################################

/DB2\(/ {
NEWLINE=$0
gsub(/PASS=user\.pass/,"PASS=user.pass",NEWLINE)
gsub(/BINDDIR=C:\\DIR\\BINDIR/,"BINDDIR=$UXDBRMLIB",NEWLINE)
gsub(/DB=DBNAME/,"DB=LINDBNAME",NEWLINE)
gsub(/VERSION=WINSIT/,"VERSION=LINSIT",NEWLINE)
print NEWLINE
next
}

{
print $0
}
