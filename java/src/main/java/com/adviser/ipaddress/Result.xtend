package com.adviser.ipaddress

import java.io.IOException
/**
 * Created by menabe on 19.06.17.
 */
class Result<T> {
    final T value;
    final String msg;
    new(T t, String msg) {
        this.value = t
        this.msg = msg
    }
    def boolean isOk() {
        return msg === null;
    }
    
    def boolean isErr() {
        return msg !== null;
    }

    def String text() {
        if (isOk()) {
            throw new IOException("try to access text");
        }
        return msg;
    }
    def T unwrap() {
        return value
    }

    def String unwrapErr() {
        return msg
    }

    def static <T> Result<T> Ok(T t) {
        return new Result<T>(t, null);
    }

    def static <T> Result<T> Err(String str) {
        return new Result<T>(null, str);
    }
}