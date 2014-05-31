# subroutines that are common to most logging scripts used by homeseer
# by Karl Smith (threadhead@gmail.com)

# this scalar declaration needs to remain at this level!
my ($dbh);

# establish the mysql connection session
sub hs_db_connect
   {
   use DBI;

   my $platform = "mysql";
   my $database = "elkm1";
   # my $host = "192.168.0.99";
   my $host = "localhost";
   my $user = "username";
   my $pw = "sekrit";

   #DATA SOURCE NAME
   my $dsn = "dbi:mysql:$database:$host;mysql_connect_timeout=20";

   # PERL DBI CONNECT
   $dbh = DBI->connect($dsn, $user, $pw)
      or die "Couldn't connect to database: " . DBI->errstr;
   }


# execute any passed sql statement
sub hs_db_execute
   {
   my $arg = shift;
   my $sth = $dbh->prepare($arg);
   $sth->execute();
   return $sth;
   }


# disconnect from the database session
sub hs_db_disconnect
   {
   $dbh->disconnect;
   }
1;