include "sage/ext/interrupt.pxi"
include "sage/ext/stdsage.pxi"

from sage.libs.flint.fmpz cimport *
from sage.libs.flint.fq_nmod cimport *
from sage.rings.integer cimport Integer
from sage.rings.finite_rings.finite_field_flint_fq_nmod cimport FiniteField_flint_fq_nmod
from sage.rings.finite_rings.element_flint_fq_nmod cimport FiniteFieldElement_flint_fq_nmod

cpdef mul_ltr(tuple P, Integer m, FiniteFieldElement_flint_fq_nmod a, FiniteFieldElement_flint_fq_nmod b):
    cdef fq_nmod_weierstrass_xz_t E
    cdef fq_nmod_ctx_struct *K
    cdef FiniteFieldElement_flint_fq_nmod x, z
    cdef fmpz_t m_fmpz 

    K = a._cparent
    x = a._new()
    z = a._new()
    fq_nmod_weierstrass_xz_init(E, K)
    fq_nmod_weierstrass_xz_set_fq_nmod(E, a.val, b.val, K)
    fmpz_init_set_readonly(m_fmpz, m.value)

    sig_on()
    fq_nmod_weierstrass_xz_mul_ltr(x.val, z.val, (<FiniteFieldElement_flint_fq_nmod>(P[0])).val, (<FiniteFieldElement_flint_fq_nmod>(P[1])).val, m_fmpz, E, K)
    sig_off()

    fmpz_clear_readonly(m_fmpz)
    fq_nmod_weierstrass_xz_clear(E, K)

    return (x, z)

def find_ordm(object E, object m):
    cdef FiniteField_flint_fq_nmod K
    K = <FiniteField_flint_fq_nmod>(E.base_ring())
    cofactor = E.cardinality()//m
    #cofactor = E.cardinality().divide_knowing_divisible_by(m)
    coprime = m.prime_divisors()

    while True:
        x = K.random_element()
        if not E.is_x_coord(x):
            continue
        P = mul_ltr((x, K(1)), cofactor, E.a4(), E.a6())
        if P[1] == 0:
            continue
        for a in coprime:
            m_a = m//a
            #m_a = m.divide_knowing_divisible_by(a)
            if mul_ltr((P[0], K(1)), m_a, E.a4(), E.a6())[1] == 0:
                break
        else:
            return P

