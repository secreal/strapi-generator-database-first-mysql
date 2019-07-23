# strapi-generator-database-first-mysql
did you use strapi.io? and has existing mysql database?

you can use this generator
windows only

what you need:
1. mysql.exe, download and install from here https://dev.mysql.com/downloads/shell/
2. put it on same folder as this generator, or just set it on environment variable
3. run the generator
4. type + and enter, then type host to your mysql database, e.g. localhost then enter
5. if you need custom port e.g. 3307, just type localhost -P3307 then enter
6. follow the instruction from generator
7. after generated, you need to move api folder to your strapi folder
8. many tables will make startup loading slower, and you can't start the server
9. find config/hook.json and set timeout to 30000 for 30 second, or you can set more
10. you need to add pool options in your config\environments\development\database.json
```
      "options": {
        "pool":{
          "min": 0,
          "max": 100,
          "idleTimeoutMillis": 300000,
          "createTimeoutMillis": 300000,
          "acquireTimeoutMillis": 300000
        }
```
11. when everything is done, just start the server

## Support on Beerpay
Hey dude! Help me out for a couple of :beers:!

[![Beerpay](https://beerpay.io/secreal/strapi-generator-database-first-mysql/badge.svg?style=beer-square)](https://beerpay.io/secreal/strapi-generator-database-first-mysql)  [![Beerpay](https://beerpay.io/secreal/strapi-generator-database-first-mysql/make-wish.svg?style=flat-square)](https://beerpay.io/secreal/strapi-generator-database-first-mysql?focus=wish)
