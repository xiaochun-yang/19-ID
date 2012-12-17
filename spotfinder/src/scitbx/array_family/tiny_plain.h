/* Copyright (c) 2001-2002 The Regents of the University of California
   through E.O. Lawrence Berkeley National Laboratory, subject to
   approval by the U.S. Department of Energy.
   See files COPYRIGHT.txt and LICENSE.txt for further details.

   Revision history:
     2002 Aug: Copied from cctbx/array_family (R.W. Grosse-Kunstleve)
     2002 Jan: Created (R.W. Grosse-Kunstleve)
 */

#ifndef SCITBX_ARRAY_FAMILY_TINY_PLAIN_H
#define SCITBX_ARRAY_FAMILY_TINY_PLAIN_H

namespace scitbx { namespace af {

  // Automatic allocation, fixed size.
  template <typename ElementType, std::size_t N>
  class tiny_plain
  {
    public:
      typedef ElementType        value_type;
      typedef ElementType*       iterator;
      typedef const ElementType* const_iterator;
      typedef ElementType&       reference;
      typedef ElementType const& const_reference;
      typedef std::size_t        size_type;
      typedef std::ptrdiff_t     difference_type;

      ElementType elems[N];

      tiny_plain() {}

      tiny_plain(
        value_type const& v0,
        value_type const& v1,
        value_type const& v2,
        value_type const& v3,
        value_type const& v4,
        value_type const& v5,
        value_type const& v6,
        value_type const& v7,
        value_type const& v8
      ) {
        this->elems[0] = v0;
        this->elems[1] = v1;
        this->elems[2] = v2;
        this->elems[3] = v3;
        this->elems[4] = v4;
        this->elems[5] = v5;
        this->elems[6] = v6;
        this->elems[7] = v7;
        this->elems[8] = v8;
      }

      static size_type size() { return N; }
      static bool empty() { return false; }
      static size_type max_size() { return N; }
      static size_type capacity() { return N; }

      ElementType& operator[](size_type i) { return elems[i]; }
      ElementType const& operator[](size_type i) const { return elems[i]; }

      void swap(ElementType* other) {
        std::swap(*this, other);
      }
  };

}} // namespace scitbx::af

#endif // SCITBX_ARRAY_FAMILY_TINY_PLAIN_H
