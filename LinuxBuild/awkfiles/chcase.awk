BEGIN {
    FS = "."
}

{
  if ( NAME ~ /U/ ) { 
      NEWNAME = ( toupper($1))
  }
  if ( NAME ~ /L/ ) { 
      NEWNAME = ( tolower($1))
  }
  if ( EXT ~ /U/ ) { 
      NEWEXT = ( toupper($2))
  }
  if ( EXT ~ /L/ ) { 
      NEWEXT = ( tolower($2))
  }

  if ( length($2) > 0 ) {
    print "mv " $1 "." $2 " " NEWNAME "." NEWEXT
  }
  else
  {
    print "mv " $1 " " NEWNAME 
  }
}

