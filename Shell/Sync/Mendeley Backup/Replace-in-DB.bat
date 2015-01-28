@echo off

(type ChangeLocation-1.sql
    echo lower^('%1'^), lower^('%2'^)
    type ChangeLocation-2.sql) > script.sql
sqlite3 <script.sql

del script.sql

