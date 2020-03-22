
研究postgresql.conf和postgresql.auto.conf两个参数文件。  

2017-10-22 21:32:58
标签：postgresql  数据库管理  参数

       

  下载LOFTER
我的照片书  |
postgresql的关于放参数的文件有2个，一个叫做postgresql.auto.conf ，另一个叫做postgresql.conf
很多同学有这样的疑问，这里文件是怎么样的一种关系，这又是怎么产生的呢？

先看一个操作。
[postgres@xiaoli pgdata]$ ls
base              pg_ident.conf  pg_stat      pg_xact
current_logfiles  pg_logical     pg_stat_tmp  postgresql.auto.conf1
global            pg_multixact   pg_subtrans  postgresql.conf
log               pg_notify      pg_tblspc    postmaster.opts
pg_commit_ts      pg_replslot    pg_twophase  postmaster.pid
pg_dynshmem       pg_serial      PG_VERSION
pg_hba.conf       pg_snapshots   pg_wal
[postgres@xiaoli pgdata]$ rm postgresql.auto.conf1
[postgres@xiaoli pgdata]$ psql
psql (10.0)
Type "help" for help.

postgres=# show work_mem;
 work_mem
----------
 4MB
(1 row)
--使用alter system命令修改参数。这个参数只会在下次重启或者重读的时候才会生效（是那种生效还给看参数）
postgres=# alter system set work_mem='1MB';
ALTER SYSTEM
postgres=# show work_mem;
 work_mem
----------
 4MB
(1 row)

postgres=# \q
--其实你alter system完成之后就会产生postgresql.auto.conf 文件了。
[postgres@xiaoli pgdata]$ ls
base              pg_ident.conf  pg_stat      pg_xact
current_logfiles  pg_logical     pg_stat_tmp  postgresql.auto.conf
global            pg_multixact   pg_subtrans  postgresql.conf
log               pg_notify      pg_tblspc    postmaster.opts
pg_commit_ts      pg_replslot    pg_twophase  postmaster.pid
pg_dynshmem       pg_serial      PG_VERSION
pg_hba.conf       pg_snapshots   pg_wal
--重启数据库。
[postgres@xiaoli pgdata]$ pg_ctl restart -D . -mf
waiting for server to shut down.... done
server stopped
waiting for server to start....2017-10-22 21:04:14.287 EDT [16325] LOG:  listening on IPv6 address "::1", port 5432
2017-10-22 21:04:14.287 EDT [16325] LOG:  listening on IPv4 address "127.0.0.1", port 5432
2017-10-22 21:04:14.288 EDT [16325] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
2017-10-22 21:04:14.295 EDT [16325] LOG:  redirecting log output to logging collector process
2017-10-22 21:04:14.295 EDT [16325] HINT:  Future log output will appear in directory "log".
 done
server started
[postgres@xiaoli pgdata]$ ls
base              pg_ident.conf  pg_stat      pg_xact
current_logfiles  pg_logical     pg_stat_tmp  postgresql.auto.conf
global            pg_multixact   pg_subtrans  postgresql.conf
log               pg_notify      pg_tblspc    postmaster.opts
pg_commit_ts      pg_replslot    pg_twophase  postmaster.pid
pg_dynshmem       pg_serial      PG_VERSION
pg_hba.conf       pg_snapshots   pg_wal
[postgres@xiaoli pgdata]$ psql
psql (10.0)
Type "help" for help.
--这时候数据库读出来的work_mem参数内容是1mb
postgres=# show work_mem;
 work_mem
----------
 1MB
(1 row)

postgres=# \q
--我们看下在work_mem分别在postgresql.conf中和postgresql.auto.conf中都是多数。
[postgres@xiaoli pgdata]$ cat postgresql.conf |grep work_mem
#work_mem = 4MB                # min 64kB
#maintenance_work_mem = 64MB        # min 1MB
#autovacuum_work_mem = -1        # min 1MB, or -1 to use maintenance_work_mem
[postgres@xiaoli pgdata]$ strings postgresql.auto.conf
# Do not edit this file manually!
# It will be overwritten by ALTER SYSTEM command.
work_mem = '1MB'
[postgres@xiaoli pgdata]$


正如所见，只有alter system修改的参数会被记录到postgresql.auto.conf中，
postgresql数据库在启动的时候会有先使用在postgresql.auto.conf中的参数。
而在postgresql.auto.conf中没有的参数会使用postgresql.conf中的。
postgresql.auto.conf中的内容也是二进制文件进行保存。
正如postgresql.auto.conf文件开头那句话所写，
# Do not edit this file manually!  不要手工编辑这个文件。
# It will be overwritten by ALTER SYSTEM command.  文件将被alter system命令覆盖。

这时候有同学又会考虑这样的一个问题，如果一个文件中有多个修改那会发生什么事情呢？
先看postgresql.auto.conf
[postgres@xiaoli pgdata]$ psql
psql (10.0)
Type "help" for help.

postgres=# show work_mem;
 work_mem
----------
 1MB
(1 row)

postgres=# alter system set work_mem='7MB';
ALTER SYSTEM
postgres=# \q
[postgres@xiaoli pgdata]$ strings postgresql.auto.conf
# Do not edit this file manually!
# It will be overwritten by ALTER SYSTEM command.
work_mem = '7MB'
[postgres@xiaoli pgdata]$ pg_ctl restart -mf -D .
waiting for server to shut down.... done
server stopped
waiting for server to start....2017-10-22 21:20:45.474 EDT [16439] LOG:  listening on IPv6 address "::1", port 5432
2017-10-22 21:20:45.474 EDT [16439] LOG:  listening on IPv4 address "127.0.0.1", port 5432
2017-10-22 21:20:45.476 EDT [16439] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
2017-10-22 21:20:45.482 EDT [16439] LOG:  redirecting log output to logging collector process
2017-10-22 21:20:45.482 EDT [16439] HINT:  Future log output will appear in directory "log".
 done
server started
[postgres@xiaoli pgdata]$ psql
psql (10.0)
Type "help" for help.

postgres=# show work_mem;
 work_mem
----------
 7MB
(1 row)

postgres=# \q
[postgres@xiaoli pgdata]$

其实他会覆盖原来的命令内容。保证文件中有且只有一个参数。


再看postgresql.conf
--先删除掉postgresql.auto.conf文件，防止他捣乱哈。
[postgres@xiaoli pgdata]$ rm postgresql.auto.conf
--在postgresql.conf文件中创造两个参数。第一个是3mb，第二个是10mb
[postgres@xiaoli pgdata]$ vi postgresql.conf
[postgres@xiaoli pgdata]$ cat postgresql.conf|grep work_mem
#work_mem = 4MB                # min 64kB
#maintenance_work_mem = 64MB        # min 1MB
#autovacuum_work_mem = -1        # min 1MB, or -1 to use maintenance_work_mem
work_mem=3MB
work_mem=10MB
--重启数据库，保证参数能生效。
[postgres@xiaoli pgdata]$ pg_ctl restart -mf -D .
waiting for server to shut down.... done
server stopped
waiting for server to start....2017-10-23 01:22:45.832 GMT [16457] LOG:  skipping missing configuration file "/pg/db/10.0/pgdata/postgresql.auto.conf"
2017-10-22 21:22:45.834 EDT [16457] LOG:  listening on IPv6 address "::1", port 5432
2017-10-22 21:22:45.834 EDT [16457] LOG:  listening on IPv4 address "127.0.0.1", port 5432
2017-10-22 21:22:45.835 EDT [16457] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
2017-10-22 21:22:45.841 EDT [16457] LOG:  redirecting log output to logging collector process
2017-10-22 21:22:45.841 EDT [16457] HINT:  Future log output will appear in directory "log".
 done
server started
[postgres@xiaoli pgdata]$ psql
psql (10.0)
Type "help" for help.

--进入到数据库中看数据库使用的是哪个参数值。
postgres=# show work_mem
postgres-# ;
 work_mem
----------
 10MB
(1 row)

postgres=# \q
[postgres@xiaoli pgdata]$ cat postgresql.conf|grep work_mem
#work_mem = 4MB                # min 64kB
#maintenance_work_mem = 64MB        # min 1MB
#autovacuum_work_mem = -1        # min 1MB, or -1 to use maintenance_work_mem
work_mem=3MB
work_mem=10MB
[postgres@xiaoli pgdata]$

那如果参数都没有写怎么办？我们再看
[postgres@xiaoli pgdata]$ cat postgresql.conf|grep work_mem
#work_mem = 4MB                # min 64kB
#maintenance_work_mem = 64MB        # min 1MB
#autovacuum_work_mem = -1        # min 1MB, or -1 to use maintenance_work_mem
work_mem=3MB
work_mem=10MB
[postgres@xiaoli pgdata]$ vi postgresql.conf
--呵呵，我都干掉了，包括哪个注释。
[postgres@xiaoli pgdata]$ cat postgresql.conf |grep work_mem
#maintenance_work_mem = 64MB        # min 1MB
#autovacuum_work_mem = -1        # min 1MB, or -1 to use maintenance_work_mem
[postgres@xiaoli pgdata]$ pg_ctl restart -mf -D .
server started
[postgres@xiaoli pgdata]$ psql
psql (10.0)
Type "help" for help.

postgres=# show work_mem;
 work_mem
----------
 4MB
(1 row)

postgres=# \q
[postgres@xiaoli pgdata]$ ls
base              pg_dynshmem    pg_notify     pg_stat_tmp  pg_wal
current_logfiles  pg_hba.conf    pg_replslot   pg_subtrans  pg_xact
global            pg_ident.conf  pg_serial     pg_tblspc    postgresql.conf
log               pg_logical     pg_snapshots  pg_twophase  postmaster.opts
pg_commit_ts      pg_multixact   pg_stat       PG_VERSION   postmaster.pid
[postgres@xiaoli pgdata]$



好了，到此我们知道了这两个参数文件的不同和效果，略微总结一下。
当数据库启动的时候发现postgresql.auto.conf文件的时候他会使用这里的参数，
如果这个postgresql.auto.conf文件不存在，那么就使用postgresql.conf文件中的内容。
当有两个参数的时候，他会使用最后的那个参数。
如果都没有，那么他会使用他内部的默认参数。
其实他那个注释里写的就是他的默认值哈。