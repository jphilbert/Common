
src("SQL Tools.r", dir.common)
require(dplyr)

ddl.data <-
  sqlFetch.Quick("misc.v_generate_tbl_ddl", db = 'redshift-sandbox')


string.bar <- paste0(rep('-', 79), collapse = '')


ddl.string <-
  ddl.data %>%
  group_by(schemaname, tablename) %>% arrange(seq) %>%
  summarize(ddl = paste0(gsub('"', '', ddl), collapse = '\n')) %>%
  group_by(schemaname) %>%
  summarize(ddl = paste0(paste0('\n\n', string.bar,
                                           '\n-- ', schemaname, '.',
                                           tablename, '\n',
                                           string.bar,
                                 '\n'),
                         ddl,
                         collapse = '')) %>%
  filter(schemaname %in%
           grep('_layer', schemaname, value = TRUE)) %>%
  data.frame


d_ply(ddl.string, 'schemaname', function(x) {
  write.table(x$ddl,
              paste0("~/desktop/DDL - ", x$schemaname[1], '.sql'),
          row.names = FALSE,
          col.names = FALSE,
          sep = '\n',
          quote = FALSE)
})




