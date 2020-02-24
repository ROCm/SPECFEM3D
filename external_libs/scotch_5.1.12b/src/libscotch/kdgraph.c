/* Copyright 2008 ENSEIRB, INRIA & CNRS
**
** This file is part of the Scotch software package for static mapping,
** graph partitioning and sparse matrix ordering.
**
** This software is governed by the CeCILL-C license under French law
** and abiding by the rules of distribution of free software. You can
** use, modify and/or redistribute the software under the terms of the
** CeCILL-C license as circulated by CEA, CNRS and INRIA at the following
** URL: "http://www.cecill.info".
**
** As a counterpart to the access to the source code and rights to copy,
** modify and redistribute granted by the license, users are provided
** only with a limited warranty and the software's author, the holder of
** the economic rights, and the successive licensors have only limited
** liability.
**
** In this respect, the user's attention is drawn to the risks associated
** with loading, using, modifying and/or developing or reproducing the
** software by the user in light of its specific status of free software,
** that may mean that it is complicated to manipulate, and that also
** therefore means that it is reserved for developers and experienced
** professionals having in-depth computer knowledge. Users are therefore
** encouraged to load and test the software's suitability as regards
** their requirements in conditions enabling the security of their
** systems and/or data to be ensured and, more generally, to use and
** operate it in the same conditions as regards security.
**
** The fact that you are presently reading this means that you have had
** knowledge of the CeCILL-C license and that you accept its terms.
*/
/************************************************************/
/**                                                        **/
/**   NAME       : kdgraph.c                               **/
/**                                                        **/
/**   AUTHOR     : Jun-Ho HER                              **/
/**                Francois PELLEGRINI                     **/
/**                                                        **/
/**   FUNCTION   : Part of a parallel bipartitioning       **/
/**                mapper.                                 **/
/**                This module handles the k-way active    **/
/**                distributed graph and save data struct- **/
/**      ure handling routines.                  **/
/**                                                        **/
/**   DATES      : # Version 5.1  : from : 31 mar 2008     **/
/**                                 to     01 jul 2008     **/
/**                                                        **/
/************************************************************/

/*
**  The defines and includes.
*/

#define KDGRAPH

#include "module.h"
#include "common.h"
#include "arch.h"
#include "dgraph.h"
#include "dmapping.h"
#include "kdgraph.h"

/************************************/
/*                                  */
/* Active dgraph handling routines. */
/*                                  */
/************************************/

/* This routine builds the active dgraph
** corresponding to the given k-way
** partition parameters.
** It returns:
** - 0   : on success.
** - !0  : on error.
*/

int
kdgraphInit (
Kdgraph * restrict const         actgrafptr,      /* Active graph */
const Dgraph * restrict const    srcgrafptr,      /* Source graph */
Dmapping * restrict const        dmapptr)         /* Mapping      */
{
/*   const Arch * restrict archptr;                  /\* Pointer to mapping architecture *\/ */
/*   ArchDom               domfrst;                  /\* First, largest domain           *\/ */
/*   Gnum                  domfrstload;              /\* Load of first domain            *\/ */
/*   Anum                  termnum; */

  actgrafptr->s          = *srcgrafptr;           /* Clone source graph */
  actgrafptr->s.flagval &= ~DGRAPHFREEALL;
  actgrafptr->levlnum    = 0;
  actgrafptr->m.mappptr  = dmapptr;
  archDomFrst (&dmapptr->archdat, &actgrafptr->m.domnorg);

/*   if ((actgrafptr->comploadavg = (Gnum *) memAlloc (actgrafptr->m.domnnbr * sizeof (Gnum) * 2)) == NULL) { */
/*     errorPrint ("kdgraphInit: out of memory"); */
/*     return     (1); */
/*   } */
/*   actgrafptr->comploaddlt = actgrafptr->comploadavg + actgrafptr->m.domnnbr; */

/*   archptr = &dmapptr->archdat; */
/*   archDomFrst (archptr, &domfrst);                /\* Get first, largest domain *\/ */
/*   domfrstload = archDomWght (archptr, &domfrst);  /\* Get its load              *\/ */

/*   actgrafptr->comploadavg[0] = (archDomWght (archptr, &actgrafptr->m.domntab[0]) * actgrafptr->s.velolocsum) / domfrstload; */
/*   actgrafptr->comploaddlt[0] = actgrafptr->s.velolocsum - actgrafptr->comploadavg[0]; */
/*   for (termnum = 1; termnum < actgrafptr->m.domnnbr; termnum ++) { */
/*     actgrafptr->comploadavg[termnum] = (archDomWght (archptr, &actgrafptr->m.domntab[termnum]) * actgrafptr->s.velolocsum) / domfrstload; */
/*     actgrafptr->comploaddlt[termnum] = - actgrafptr->comploadavg[termnum]; */
/*   } */

/*   actgrafptr->fronlocnbr = 0;                       /\* No frontier yet *\/ */
/*   actgrafptr->fronloctab = NULL; */
/*   actgrafptr->commload   = 0; */
/*   actgrafptr->levlnum    = 0; */
/*   actgrafptr->leafnum    = 0; */

  return (0);
}

/* This routine frees the contents
** of the given active graph
** It returns:
** - VOID  : in all cases.
*/

void
kdgraphExit (
Kdgraph  * restrict const    actgrafptr)          /* Active graph */
{
  dgraphExit (&actgrafptr->s);

#ifdef SCOTCH_DEBUG_KDGRAPH1
  memSet (actgrafptr, 0, sizeof (Kdgraph));
#endif /* SCOTCH_DEBUG_KDGRAPH1 */
}
