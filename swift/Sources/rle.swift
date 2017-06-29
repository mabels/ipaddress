


class Last<T: Equatable&Hashable> {
    var val: Rle<T>?
    var max_poses = [T: [Int]]()
    var ret: [Rle<T>] = [Rle<T>]()

    public init() { }
    
    func handle_last() {
        if (nil == val) {
            return;
        }
        let _last = val!;
        var max_rles = max_poses[_last.part];
        if (max_rles == nil) {
            max_rles = [Int]();
            max_poses[_last.part] = max_rles;
        }
        // console.log(_last.part, max_poses);
        for idx in max_rles! {
            let prev = ret[max_rles![idx]];
            if (prev.cnt > _last.cnt) {
                // console.log(`>>>>> last=${_last}->${idx}->prev=${prev}`);
                _last.max = false;
            } else if (prev.cnt == _last.cnt) {
                // nothing
            } else if (prev.cnt < _last.cnt) {
                // console.log(`<<<<< last=${_last}->${idx}->prev=${prev}`);
                prev.max = false;
            }
        }
        //println!("push:{}:{:?}", self.ret.len(), _last);
        max_rles!.append(ret.count);
        _last.pos = ret.count;
        ret.append(_last);
    }
}

class Rle<T: Equatable&Hashable> {
    var part: T;
    var pos = 0;
    var cnt = 0;
    var max: Bool = false;

    init(part: T, pos: Int, cnt: Int, max: Bool) {
        self.part = part;
        self.pos = pos;
        self.cnt = cnt;
        self.max = max;
    }

    func toString() -> String {
        return "<Rle@part:\(part),pos\(pos),cnt:\(cnt),max:\(max)>";
    }

    func eq(_ other: Rle<T>) -> Bool {
        return part == other.part && pos == other.pos &&
            cnt == other.cnt && max == other.max;
    }
    func ne(_ other: Rle<T>) -> Bool {
        return !eq(other);
    }

    class func code<T: Equatable&Hashable>(_ parts: [T]) -> [Rle<T>] {
        let last = Last<T>();
        // println!("code");
        for part in parts {
            // console.log(`part:${part}`);
            if (last.val != nil && last.val!.part == part) {
                last.val!.cnt += 1;
            } else {
                last.handle_last();
                last.val = Rle<T>(part: part, pos: 0, cnt: 1, max: true);
            }
        }
        last.handle_last();
        return last.ret;
    }

}

