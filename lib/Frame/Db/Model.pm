use Object::Pad qw(:experimental(:all));

package Frame::Db::Model;
role Frame::Db::Model : does(Frame::Db);

use utf8;
use v5.40;

use DBI;
use DBD::SQLite;
use Data::Printer;
use Hash::Ordered;

#use Exporter;

use constant COLUMN_ATTR => qw(Type Primary Foreign Autoinc Notnull);

field $table : param;
field $columns : mutator : param     //= Hash::Ordered->new;
field $constraints : mutator : param //= Hash::Ordered->new;

field $sqla;
field $dbh;

#field $driver;

BEGIN {
    $^H{ __PACKAGE__ . "/dbmodel" };
}

APPLY($mop) {
    my $class = $mop->name;

    #$class->import;
    $^H{"$class/dbmodel"} = 1;

    foreach my $colattr (COLUMN_ATTR) {
        Object::Pad::MOP::FieldAttr->register(
            $colattr,
            permit_hintkey => "$class/dbmodel",
            apply          => sub { $class->$colattr }
        );
    }

    $^H{"$class/dbmodel"} = 1;

    p %^H
}

ADJUST {
    $sqla = $self->app->sqla;
    $dbh  = $self->app->dbh;

    #($driver) = $self->app->config->{db}{source} =~ /dbi:([^:]+):.+/;
}

method create_table {
    my @fields;

    foreach my $name ( $columns->keys ) {
        my $column = $columns->get($name);

        $$column{type} //= 'TEXT';

        $$column{sql_type} = 'TEXT'
          if $$column{type} eq 'JSON';

        $$column{sql_type} = 'INTEGER'
          if $$column{type} eq 'Time::Moment';

        my $field = "$name " . ( $$column{sql_type} || $$column{type} );

        $field .= ' PRIMARY KEY'   if $$column{primary_key};
        $field .= ' AUTOINCREMENT' if $$column{autoincrement};
        $field .= ' NOT NULL'      if $$column{not_null};

        $field .= " REFERENCES $$column{foreign_key}" if $$column{foreign_key};

        push @fields, $field;
    }

    push @fields, "attr TEXT";

    foreach my $key ( $constraints->keys ) {
        my $val = $constraints->get($key);
        my $field;

        if ( $key eq 'primary_key' ) {
            $field = 'PRIMARY KEY (' . join ',', @$val . ')';
        }

        push @fields, $field;
    }

    my $sql = $self->app->sqla->generate( 'CREATE TABLE IF NOT EXISTS',
        \$table, \@fields );

    my $sth = $self->app->dbh->prepare($sql);
    $sth->execute;
}

# method table_exists {
#   my $sth = $dbh->prepare("");
#   $sth->execute;

#   $sth->fetchrow_array
# }

method $type : common ($meta, $val = 'TEXT') { p( $class, $meta, $val ) }

  method $primarykey : common ($meta, $val) {

  }

  method $foreign : common ($meta, $val) {

  }

  method $autoinc : common ($meta, $val) {

  }

  method $notnull : common ($meta, $val) {

  }

  # method import :override :common {
  #   $^H{"$class/dbmodel"}
  # }

  # method import :common :override {
  #   $^H{"$class/dbmodel"} = 1;

  #   foreach my $colattr (COLUMN_ATTR) {
  #     my $method = lc $colattr;
  #     Object::Pad::MOP::FieldAttr->register(
  #       $colattr,
  #       permit_hintkey => "$class/dbmodel",
  #       apply => sub { $class->$method }
  #     )
  #   }

  #   $^H{"$class/dbmodel"} = 1
  # }
