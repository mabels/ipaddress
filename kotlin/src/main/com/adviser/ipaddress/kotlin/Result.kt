package com.adviser.ipaddress.kotlin

import java.io.IOException


/**
 * Created by menabe on 19.06.17.
 */
class Result<T>(val value: T?, val msg: String?) {

    fun isOk(): Boolean {
        return msg === null
    }

    fun isErr(): Boolean {
        return msg !== null
    }

    fun text(): String {
        if (isOk()) {
            throw IOException("try to access text")
        }
        return msg!!
    }

    fun unwrap(): T {
        return value!!
    }

    fun unwrapErr(): String {
        return msg!!
    }

    companion object {
        fun <T> Ok(t: T): Result<T> {
            return Result<T>(t, null)
        }

        fun <T> Err(str: String): Result<T> {
            return Result<T>(null, str)
        }

    }
}

