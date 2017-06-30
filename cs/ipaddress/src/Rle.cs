using System;
using System.Collections.Generic;

namespace ipaddress
{
  class Last
  {
    public Rle value;
    public Dictionary<long, List<int>> max_poses = new Dictionary<long, List<int>>();
    public List<Rle> ret = new List<Rle>();

    public void handle_last()
    {
      if (null == this.value)
      {
        return;
      }
      var _last = this.value;

      List<int> max_rles;
      if (max_poses.ContainsKey(_last.part))
      {
        max_rles = new List<int>();
        max_poses.Add(_last.part, max_rles);
      }
      else
      {
        max_rles = max_poses[_last.part];
      }

      foreach (var idx in max_rles)
      {
        var prev = this.ret[idx];
        if (prev.cnt > _last.cnt)
        {
          // println!(">>>>> last={:?}->{}->prev={:?}", _last, idx, prev);
          _last.max = false;
        }
        else if (prev.cnt == _last.cnt)
        {
          // nothing
        }
        else if (prev.cnt < _last.cnt)
        {
          // println!("<<<<< last={:?}->{}->prev={:?}", _last, idx, prev);
          //this.ret[idx].max = false;
          prev.max = false;
        }
      }
      //println!("push:{}:{:?}", this.ret.len(), _last);
      max_rles.Add(this.ret.Count);
      _last.pos = this.ret.Count;
      this.ret.Add(_last);
    }
  }


  class Rle
  {
    public int part;
    public int pos;
    public int cnt;
    public bool max;

    public Rle(int part, int pos, int cnt, bool max)
    {
      this.part = part;
      this.pos = pos;
      this.cnt = cnt;
      this.max = max;
    }

    public String Inspect()
    {
      return "<Rle@part:{:x},pos:{},cnt:{},max:{}> self.part, self.pos, self.cnt, self.max)";
    }

    public bool eq(Rle other)
    {
      return this.part == other.part && this.pos == other.pos &&
                    this.cnt == other.cnt && this.max == other.max;
    }


    public static List<Rle> code(List<int> parts)
    {
      var last = new Last();
      // println!("code");
      for (var i = 0; i < parts.Count; i++)
      {
        var part = parts[i];
        // println!("part:{}", part);
        if (last.value != null && last.value.part == part)
        {
          last.value.cnt += 1;
        }
        else
        {
          last.handle_last();
          last.value = new Rle(part, 0, 1, true);
        }
      }
      last.handle_last();
      return last.ret;
    }
  }
}
