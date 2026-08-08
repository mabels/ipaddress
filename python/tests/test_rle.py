from ip_address.rle import Rle


def assert_rle(left, right):
    assert len(left) == len(right), "array length missmatch"
    for i in range(len(left)):
        assert left[i].eq(right[i]), f"left:{left[i]} right:{right[i]}"


def test_rle():
    assert_rle(Rle.code([]), [])
    assert_rle(Rle.code([4711]), [Rle(4711, 0, 1, True)])
    assert_rle(Rle.code([4711, 4711]), [Rle(4711, 0, 2, True)])
    assert_rle(
        Rle.code([4711, 4711, 4811]),
        [
            Rle(4711, 0, 2, True),
            Rle(4811, 1, 1, True),
        ],
    )
    assert_rle(
        Rle.code([4711, 4711, 4811, 4711, 4711]),
        [
            Rle(4711, 0, 2, True),
            Rle(4811, 1, 1, True),
            Rle(4711, 2, 2, True),
        ],
    )
    assert_rle(
        Rle.code([4711, 4711, 4711, 4811, 4711, 4711]),
        [
            Rle(4711, 0, 3, True),
            Rle(4811, 1, 1, True),
            Rle(4711, 2, 2, False),
        ],
    )
    assert_rle(
        Rle.code([4711, 4711, 4711, 4811, 4711, 4711, 4911, 4911, 4911]),
        [
            Rle(4711, 0, 3, True),
            Rle(4811, 1, 1, True),
            Rle(4711, 2, 2, False),
            Rle(4911, 3, 3, True),
        ],
    )

    assert_rle(
        Rle.code([0x2001, 0x888, 0, 0x6630, 0, 0, 0, 0]),
        [
            Rle(0x2001, 0, 1, True),
            Rle(0x888, 1, 1, True),
            Rle(0, 2, 1, False),
            Rle(0x6630, 3, 1, True),
            Rle(0, 4, 4, True),
        ],
    )
