


public class Last<T: Equatable&Hashable> {
  var val: Rle<T>?;
  var max_poses = [T: [Int]]();
  var ret: [Rle<T>] = [Rle<T>]();
  
  public init() { }
  
  func handle_last() {
    if (nil == val) {
      return;
    }
    let _last = val!;
    var max_rles = max_poses[_last.part];
    if (max_rles == nil) {
      max_rles = [Int]();
      //print("handle_last:push:\(_last.part)")
      max_poses[_last.part] = max_rles;
    }
    //print("\(_last.part), \(max_rles!)");
    for idx in max_rles! {
      let prev = ret[idx];
      if (prev.cnt > _last.cnt) {
        //print(">>>>> last=\(_last)->\(idx)->prev=\(prev)");
        _last.max = false;
      } else if (prev.cnt == _last.cnt) {
        // nothing
      } else if (prev.cnt < _last.cnt) {
        //print("<<<<< last=\(_last)->\(idx)->prev=\(prev)");
        prev.max = false;
      }
    }
    //println!("push:{}:{:?}", self.ret.len(), _last);
    max_rles!.append(ret.count);
    _last.pos = ret.count;
    ret.append(_last);
    max_poses[_last.part] = max_rles // funky swift
  }
}


public class Rle<T: Equatable&Hashable>: Equatable, CustomStringConvertible {
  var part: T;
  var pos = 0;
  var cnt = 0;
  var max: Bool = false;
  
  public init(part: T, pos: Int, cnt: Int, max: Bool) {
    self.part = part;
    self.pos = pos;
    self.cnt = cnt;
    self.max = max;
  }
  
  public var description: String {
    return "<Rle@part:\(part),pos\(pos),cnt:\(cnt),max:\(max)>";
  }
  
  public final class func ==(lhs: Rle<T>, rhs: Rle<T>) -> Bool {
    return lhs.eq(rhs)
  }
  
  public func eq(_ other: Rle<T>) -> Bool {
    return part == other.part && pos == other.pos &&
      cnt == other.cnt && max == other.max;
  }
  public func ne(_ other: Rle<T>) -> Bool {
    return !eq(other);
  }
  
  public class func code<T: Equatable&Hashable>(_ parts: [T]) -> [Rle<T>] {
    let last = Last<T>();
    //print("code");
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
