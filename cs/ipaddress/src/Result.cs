using System;
using System.Collections.Generic;

namespace ipaddress
{

  class Result<T> 
  {
    T value;
    String msg;
    Result(T t, String msg)
    {
      this.value = t;
      this.msg = msg;
    }
    public bool isOk()
    {
      return msg == null;
    }

    public bool isErr()
    {
      return msg != null;
    }

    public String text()
    {
      if (isOk())
      {
        throw new Exception("try to access text");
      }
      return msg;
    }
    public T unwrap()
    {
      return value;
    }

    public String unwrapErr()
    {
      return msg;
    }

    public static Result<T> Ok(T t)
    {
      return new Result<T>(t, null);
    }

    public static Result<T> Err(String str)
    {
      return new Result<T>(default(T), str);
    }
  }
}