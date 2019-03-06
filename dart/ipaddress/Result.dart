/**
 * Created by menabe on 19.06.17.
 */
class Result<T extends Object> {

    final T value;
    final String msg;

    Result.Ok(this.value, { this.msg = null });

    Result.Err(this.msg, { this.value = null });

    Result(this.value, this.msg);

    bool isOk() {
        return msg == null;
    }

    bool isErr() {
        return msg != null;
    }

    String text() {
        if (isOk()) {
            throw Exception("try to access text");
        }
        return msg;
    }
    T unwrap() {
        return value;
    }

    String unwrapErr() {
        return msg;
    }


}
