#ifndef __MOCHA__
#define __MOCHA__

#include <iostream>
#include <exception>
#include "chai.hpp"
#include <stdlib.h>
#include <functional>

typedef std::function<void()> MochaAction;

static int failCount = 0;
static int okCount = 0;


int exit() {
  std::cout << std::endl;
  std::stringstream s2;
  s2 << std::dec << "Total " << okCount+failCount
    << " Ok " << okCount
    << " Fail " << failCount
    << " Assertions " << Chai::assert.count;

  std::stringstream cmake;
  cmake << "cmake -E cmake_echo_color --";
   if (failCount) {
     cmake << "red";
   } else {
     cmake << "green";
   }
  cmake << " --bold " << "'" << s2.str() << "'";
  auto ret = system(cmake.str().c_str());
  if (ret) {
    std::cout << cmake.str() << std::endl;
  }
  std::cout << std::endl;
  std::exit(std::min(failCount, 27));
}

static const char *describeContext = "";
void describe(const char *title, const MochaAction &action) {
  std::cout << "Test:" << title << std::endl;
  describeContext = title;
  (action)();
}

void it(const char *title, const MochaAction &action) {
  try {
    (action)();

    auto ret = system("cmake -E cmake_echo_color --green --bold --no-newline '   ✓ '");
    if (ret) { std::cout << "   FINE "; }
    std::cout << describeContext << ":" << title << std::endl;
    ++okCount;
  } catch (Chai::AssertError &e) {
    auto ret = system("cmake -E cmake_echo_color --red --bold --no-newline '   - '");
    if (ret) { std::cout << "   FAIL "; }
    std::cout << describeContext << ":" << title << " " << e.what() << std::endl;
    ++failCount;
  }
}

#endif
