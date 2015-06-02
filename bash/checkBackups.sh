#!/bin/bash

perl checkbackup.perl --snapshotinterval 600 --warningGracePeriod 86400 --snapshottime 10 --anybarFailureColor red --anyBarPortNumber 1738 --datasets zfspower/Users,zfspower/Users/justin
perl checkbackup.perl --snapshotinterval 3600 --warningGracePeriod 86400 --snapshottime 1200 --anybarFailureColor white --anyBarPortNumber 1739 --datasets zfssnaps/backup/Users,zfssnaps/backup/Users/justin