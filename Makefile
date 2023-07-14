MODULE_big = parquet_s3_fdw
OBJS = src/common.o src/reader.o src/exec_state.o src/parquet_impl.o src/parquet_fdw.o src/slvars.o src/modify_reader.o src/modify_state.o
# Add file for S3
OBJS += parquet_s3_fdw.o parquet_s3_fdw_connection.o parquet_s3_fdw_server_option.o

PGFILEDESC = "parquet_s3_fdw - foreign data wrapper for parquet on S3"

SHLIB_LINK = -lm -lstdc++ -lparquet -larrow
# Add libraries for S3
SHLIB_LINK += -laws-cpp-sdk-core -laws-cpp-sdk-s3

EXTENSION = parquet_s3_fdw
DATA = parquet_s3_fdw--0.1.sql parquet_s3_fdw--0.1--0.2.sql parquet_s3_fdw--0.2--0.3.sql parquet_s3_fdw--0.3.sql

REGRESS = import_server parquet_s3_fdw_server parquet_s3_fdw_post_server parquet_s3_fdw_modify_server schemaless/schemaless_server schemaless/import_server schemaless/parquet_s3_fdw_server schemaless/parquet_s3_fdw_post_server schemaless/parquet_s3_fdw2 schemaless/parquet_s3_fdw_modify_server aws_region

# parquet_impl.cpp requires C++ 17.
override PG_CXXFLAGS += -std=c++17 -O3

# pass CCFLAGS (when defined) to both C and C++ compilers.
ifdef CCFLAGS
	override PG_CXXFLAGS += $(CCFLAGS)
	override PG_CFLAGS += $(CCFLAGS)
endif

# PostgreSQL uses link time optimization option which may break compilation
# (this happens on travis-ci). Redefine COMPILE.cxx.bc without this option.
COMPILE.cxx.bc = $(CLANG) -xc++ -std=c++17 -O3 -Wno-error=register -Wno-deprecated-register -Wno-ignored-attributes $(BITCODE_CXXFLAGS) $(CPPFLAGS) $(CCFLAGS) -emit-llvm -c

ifdef USE_PGXS
	PG_CONFIG = pg_config
	PGXS := $(shell $(PG_CONFIG) --pgxs)
	include $(PGXS)

	# XXX: PostgreSQL below 11 does not automatically add -fPIC or equivalent to C++
	# flags when building a shared library, have to do it here explicitely.
	ifeq ($(shell test $(VERSION_NUM) -lt 110000; echo $$?), 0)
		override CXXFLAGS += $(CFLAGS_SL)
	endif
else
	subdir = contrib/parquet_s3_fdw
	top_builddir = ../..

	include $(top_builddir)/src/Makefile.global
	include $(top_srcdir)/contrib/contrib-global.mk
endif

ifdef REGRESS_PREFIX
	REGRESS_PREFIX_SUB = $(REGRESS_PREFIX)
	else
	REGRESS_PREFIX_SUB = $(VERSION)
endif

REGRESS := $(addprefix $(REGRESS_PREFIX_SUB)/,$(REGRESS))
$(shell mkdir -p results/$(REGRESS_PREFIX_SUB))
$(shell mkdir -p results/$(REGRESS_PREFIX_SUB)/schemaless)
