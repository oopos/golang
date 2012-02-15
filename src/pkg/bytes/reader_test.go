// Copyright 2012 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package bytes_test

import (
	. "bytes"
	"os"
	"testing"
)

func TestReader(t *testing.T) {
	r := NewReader([]byte("0123456789"))
	tests := []struct {
		off     int64
		seek    int
		n       int
		want    string
		wantpos int64
		seekerr string
	}{
		{seek: os.SEEK_SET, off: 0, n: 20, want: "0123456789"},
		{seek: os.SEEK_SET, off: 1, n: 1, want: "1"},
		{seek: os.SEEK_CUR, off: 1, wantpos: 3, n: 2, want: "34"},
		{seek: os.SEEK_SET, off: -1, seekerr: "bytes: negative position"},
		{seek: os.SEEK_SET, off: 1<<31 - 1},
		{seek: os.SEEK_CUR, off: 1, seekerr: "bytes: position out of range"},
		{seek: os.SEEK_SET, n: 5, want: "01234"},
		{seek: os.SEEK_CUR, n: 5, want: "56789"},
		{seek: os.SEEK_END, off: -1, n: 1, wantpos: 9, want: "9"},
	}

	for i, tt := range tests {
		pos, err := r.Seek(tt.off, tt.seek)
		if err == nil && tt.seekerr != "" {
			t.Errorf("%d. want seek error %q", i, tt.seekerr)
			continue
		}
		if err != nil && err.Error() != tt.seekerr {
			t.Errorf("%d. seek error = %q; want %q", i, err.Error(), tt.seekerr)
			continue
		}
		if tt.wantpos != 0 && tt.wantpos != pos {
			t.Errorf("%d. pos = %d, want %d", i, pos, tt.wantpos)
		}
		buf := make([]byte, tt.n)
		n, err := r.Read(buf)
		if err != nil {
			t.Errorf("%d. read = %v", i, err)
			continue
		}
		got := string(buf[:n])
		if got != tt.want {
			t.Errorf("%d. got %q; want %q", i, got, tt.want)
		}
	}
}