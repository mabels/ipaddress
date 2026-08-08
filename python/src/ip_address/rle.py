from typing import Dict, List, Optional


class Rle:
    def __init__(self, part: int, pos: int, cnt: int, max: bool):
        self.part = part
        self.pos = pos
        self.cnt = cnt
        self.max = max

    def __str__(self) -> str:
        return f"<Rle@part:{self.part},pos:{self.pos},cnt:{self.cnt},max:{self.max}>"

    def eq(self, other: "Rle") -> bool:
        return self.part == other.part and self.pos == other.pos and self.cnt == other.cnt and self.max == other.max

    def ne(self, other: "Rle") -> bool:
        return not self.eq(other)

    @staticmethod
    def code(parts: List[int]) -> List["Rle"]:
        last = _Last()
        for part in parts:
            if last.val is not None and last.val.part == part:
                last.val.cnt += 1
            else:
                last.handle_last()
                last.val = Rle(part, 0, 1, True)
        last.handle_last()
        return last.ret


class _Last:
    def __init__(self):
        self.val: Optional[Rle] = None
        self.max_poses: Dict[int, List[int]] = {}
        self.ret: List[Rle] = []

    def handle_last(self) -> None:
        if self.val is None:
            return
        last = self.val
        max_rles = self.max_poses.setdefault(last.part, [])
        for pos_in_ret in max_rles:
            prev = self.ret[pos_in_ret]
            if prev.cnt > last.cnt:
                last.max = False
            elif prev.cnt < last.cnt:
                prev.max = False
        max_rles.append(len(self.ret))
        last.pos = len(self.ret)
        self.ret.append(last)


__all__ = ["Rle"]
