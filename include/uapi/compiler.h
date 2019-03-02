/*
 * Copyright (c) 2019，Wuklab, Purdue University.
 */

/*
 * Some general compiler related annotations.
 * Extracted from linux/compiler.h
 *
 * Used by both HLS and host side code.
 */

#ifndef _LEGOFPGA_COMPILER_H_
#define _LEGOFPGA_COMPILER_H_

#define NR_BITS_PER_BYTE	(8)
#define NR_BITS_PER_LONG	(64)

#define __unused		__attribute__((__unused__))
#define __maybe_unused		__attribute__((__unused__))
#define __noreturn		__attribute__((__noreturn__))
#define __packed		__attribute__((__packed__))
#define __aligned(x)            __attribute__((aligned(x)))

#define likely(x)		__builtin_expect(!!(x), 1)
#define unlikely(x)		__builtin_expect(!!(x), 0)

#define __compiletime_error_fallback(condition)			\
	do {							\
		((void)sizeof(char[1 - 2 * condition]));	\
	} while (0)

#define __compiletime_assert(condition, msg, prefix, suffix)	\
	do {							\
		bool __cond = !(condition);			\
		extern void prefix ## suffix(void) __compiletime_error(msg); \
		if (__cond)					\
			prefix ## suffix();			\
		__compiletime_error_fallback(__cond);		\
	} while (0)

#define _compiletime_assert(condition, msg, prefix, suffix)	\
	__compiletime_assert(condition, msg, prefix, suffix)

/**
 * compiletime_assert - break build and emit msg if condition is false
 * @condition: a compile-time constant condition to check
 * @msg:       a message to emit if condition is false
 *
 * In tradition of POSIX assert, this macro will break the build if the
 * supplied condition is *false*, emitting the supplied error message if the
 * compiler has support to do so.
 */
#define compiletime_assert(condition, msg)			\
	_compiletime_assert(condition, msg, __compiletime_assert_, __LINE__)

#undef offsetof
#ifdef __compiler_offsetof
#define offsetof(TYPE, MEMBER)	__compiler_offsetof(TYPE, MEMBER)
#else
#define offsetof(TYPE, MEMBER)	((size_t)&((TYPE *)0)->MEMBER)
#endif

/**
 * offsetofend(TYPE, MEMBER)
 *
 * @TYPE: The type of the structure
 * @MEMBER: The member within the structure to get the end offset of
 */
#define offsetofend(TYPE, MEMBER) \
	(offsetof(TYPE, MEMBER)	+ sizeof(((TYPE *)0)->MEMBER))

#endif /* _LEGOFPGA_COMPILER_H_ */
