package com.adviser.ipaddress

import java.io.IOException



/**
 * Created by menabe on 19.06.17.
 */
class Result<T>(t: T?, msg: String?) {
    val value = t;
    val msg = msg;

    public fun isOk(): Boolean {
        return msg === null;
    }
    
    public fun isErr(): Boolean {
        return msg !== null;
    }

    public fun text(): String {
        if (isOk()) {
            throw IOException("try to access text");
        }
        return msg!!;
    }

    public fun unwrap(): T {
        return value!!
    }

    public fun unwrapErr(): String {
        return msg!!
    }

    companion object {
        fun <T> Ok(t: T): Result<T> {
            return Result<T>(t, null);
        }

        fun <T> Err(str: String): Result<T> {
            return Result<T>(null, str);
        }

    }
}

