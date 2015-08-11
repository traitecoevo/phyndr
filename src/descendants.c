#include <R.h>
#include <Rinternals.h>

int descendants(int node, int *edge, int nedge, int ntip, int *desc);

SEXP r_descendants(SEXP node, SEXP edge, SEXP ntip) {
  int nedge = nrows(edge), *desc = (int *)R_alloc(nedge, sizeof(int));
  int n, *ret_c, node_c = INTEGER(node)[0];
  SEXP ret;
  n = descendants(node_c, INTEGER(edge), nedge,
                  INTEGER(ntip)[0], desc);
  PROTECT(ret = allocVector(INTSXP, n+1));
  ret_c = INTEGER(ret);
  ret_c[0] = node_c;
  memcpy(ret_c + 1, desc, n*sizeof(int));
  UNPROTECT(1);
  return ret;
}

/* if column 1 was sorted, this would be faster... */
int descendants(int node, int *edge, int nedge, int ntip, int *desc) {
  const int *from = edge, *to = edge + nedge;
  int i, n = 0, ni;
  for ( i = 0; i < nedge; i++ ) {
    if ( from[i] == node ) {
      *desc = to[i];
      if (to[i] > ntip) { /* R indexing... */
        ni = descendants(to[i], edge, nedge, ntip, desc+1) + 1;
      } else {
        ni = 1;
      }
      n += ni;
      desc += ni;
    }
  }
  return n;
}
