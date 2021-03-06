//--------------------------------------------------------------------*- C++ -*-
// CLING - the C++ LLVM-based InterpreterG :)
// author:  Axel Naumann <axel@cern.ch>
//
// This file is dual-licensed: you can choose to license it under the University
// of Illinois Open Source License or the GNU Lesser General Public License. See
// LICENSE.TXT for details.
//------------------------------------------------------------------------------

#ifndef CLING_CIFACTORY_H
#define CLING_CIFACTORY_H

#include "clang/Frontend/CompilerInstance.h"

#include "llvm/ADT/StringRef.h"

namespace llvm {
  class LLVMContext;
  class MemoryBuffer;
}

namespace clang {
  class DiagnosticsEngine;
}

namespace cling {
  class DeclCollector;
  class CIFactory {
  public:
    // TODO: Add overload that takes file not MemoryBuffer
    static clang::CompilerInstance* createCI(llvm::StringRef code,
                                             int argc,
                                             const char* const *argv,
                                             const char* llvmdir);

    static clang::CompilerInstance* createCI(llvm::MemoryBuffer* buffer,
                                             int argc,
                                             const char* const *argv,
                                             const char* llvmdir,
                                             DeclCollector* stateCollector);
  private:
    //---------------------------------------------------------------------
    //! Constructor
    //---------------------------------------------------------------------
    CIFactory() = delete;
    ~CIFactory() = delete;
  };
} // namespace cling
#endif // CLING_CIFACTORY_H
