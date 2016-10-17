

#include <cascara/cascara.hpp>
using namespace cascara;

#include "../src/option.hpp"

using namespace ipaddress;

int c_count = 0;
class TestOptional {
  public:
    int _42;
    TestOptional() : _42(42) { c_count++; }
    ~TestOptional() { --c_count; }

};

int main(int, char **) {

  describe("#option", [](){

      it("default", [](){
          auto none = Option<TestOptional>();
          assert.isTrue(none.isNone());
          assert.isFalse(none.isSome());
          try {
            none.unwrap();
            assert.isTrue(true, "unwrap should not work");
          } catch (OptionError e) {
          }
      });

      it("None", [](){
          auto none = None<TestOptional>();
          assert.isTrue(none.isNone());
          assert.isFalse(none.isSome());
          try {
            none.unwrap();
            assert.isTrue(true, "unwrap should not work");
          } catch (OptionError e) {
          }
      });

      it("Some", [](){
          TestOptional to;
          auto some = Some(to);
          to._42 = 8199;
          assert.isFalse(some.isNone());
          assert.isTrue(some.isSome());
          assert.equal(some.unwrap()._42, 42);
          some.unwrap()._42 = 4711;
          assert.equal(some.unwrap()._42, 4711);
      });
      it("Memory", [](){
          TestOptional to;
          c_count = 0;
          {
            auto some = Some(to);
            assert.equal(c_count, 1);
            assert.equal(some.unwrap()._42, 42);
          }
          assert.equal(c_count, 0, "loosing memory");
      });

      it("Ptr", [](){
          TestOptional to;
          auto some = Some(to);
          assert.equal(some->_42, 42);
      });

  });
  return exit();

}
