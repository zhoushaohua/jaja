# 正确设置open_cursors和'session_cached_cursors'  可以减少sql解析，提高系统性能，那么，如何正确设置'session_cached_cursors'  这个参数呢？我们可以把握下面的原则

1、'session_cached_cursors'  数量要小于open_cursor

2、要考虑共享池的大小

3、使用下面的sql判断'session_cached_cursors'  的使用情况。如果使用率为100%则增大这个参数值。

```sql
SELECT 'session_cached_cursors' parameter,
       lpad(VALUE, 5) VALUE,
       decode(VALUE, 0, '  n/a', to_char(100 * used / VALUE, '990') || '%') usage
  FROM (SELECT MAX(s.VALUE) used
          FROM v$statname n, v$sesstat s
         WHERE n.NAME = 'session cursor cache count'
           AND s.statistic# = n.statistic#),
       (SELECT VALUE FROM v$parameter WHERE NAME = 'session_cached_cursors')
UNION ALL
SELECT 'open_cursors',
       lpad(VALUE, 5),
       to_char(100 * used / VALUE, '990') || '%'
  FROM (SELECT MAX(SUM(s.VALUE)) used
          FROM v$statname n, v$sesstat s
         WHERE n.NAME IN
               ('opened cursors current', 'session cursor cache count')
           AND s.statistic# = n.statistic#
         GROUP BY s.sid),
       (SELECT VALUE FROM v$parameter WHERE NAME = 'open_cursors')
```

```bash
PARAMETER              VALUE      USAGE
---------------------- ---------- -----
session_cached_cursors    50        98%
open_cursors             300        30%
```

如果以上命中率为100%，则调整响应的值
