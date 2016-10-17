
#include <cascara/cascara.hpp>
using namespace cascara;

#include "../src/result.hpp"

using namespace ipaddress;

class TestOptional {
  public:
    int _42;
    TestOptional() : _42(42) {}
};

int main(int, char **) {

  describe("#result", [](){

      it("Error", [](){
          auto err = Err<TestOptional>("testcase");
          assert.isTrue(err.isErr());
          assert.isFalse(err.isOk());
          assert.equal(err.text(), "testcase");
          try {
            err.unwrap();
            assert.isTrue(true, "unwrap should not work");
          } catch (OptionError e) {
          }
      });

      it("Some", [](){
          TestOptional to;
          auto some = Ok(to);
          assert.isFalse(some.isErr());
          assert.isTrue(some.isOk());
          assert.equal(some.unwrap()._42, 42);
          some.unwrap()._42 = 4711;
          assert.equal(some.unwrap()._42, 4711);
      });

      it("Ptr", [](){
          TestOptional to;
          auto some = Ok(to);
          assert.isFalse(some.isErr());
          assert.isTrue(some.isOk());
          assert.equal(some->_42, 42);
          some->_42 = 4711;
          assert.equal(some->_42, 4711);
      });


  });
  return exit();
}
