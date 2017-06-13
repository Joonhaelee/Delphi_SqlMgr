# Delphi_SqlMgr
Database object container for delphi. Got inspiration from Ibatis 

SqlMgr class encapsulate sql jobs such as loading object, execute script.
It can load one or multiple database object to mapped pascal objects.

how to use 
1. Write sql script
  - Look files under sql folder. Its syntax is similar with XML even it is slightly different.
  - Each sql must be identified by its name uniquely and the result must be matched with bean class name
2. Write mapped bean class
  - It should be descendant of TPersistent. Recommand to make it descendant of TNData.
  - The database fields must be defined public member in your class.
3. On your application.
  - Make an instance of TNSqlManager(For test, It should be TNFDSqlMgr - it support FireDac library)
    And assign it to the global variable "gsm" defined in NLibSqlMgr
  - Load sql script with the methods named gsm.LoadSqlFile(), gsm.LoadSqlFiles().
  - If you want a single object, Use gsm.GetObject()
  - If you want multiple objects, Use gsm.GetList()
  - If you want paged objects, Use gsm.GetPageList()
  - If you want a atomic value, Use gsm.GetValue()
  - If you want to change data, Call gsm.Execute()
  
These sources compiled on Delphi 10.1(Berlin)
And even though there is no application for testing, I think it would be enough to know how it was designed and implemented.
All rights reserved to Joonhae.lee@gmail.com.
  
  
    

