// errchk $G -e $D/$F.go

// Copyright 2011 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package main

// Test that error messages say what the source file says
// (uint8 vs byte).

func f(byte) {}
func g(uint8) {}

func main() {
	var x int
	f(x)  // ERROR "byte"
	g(x)  // ERROR "uint8"
}
