CFLAGS := -D_REENTRANT -Wall -pedantic -Isrc
CFLAGS += -fPIC -g
LDFLAGS = -lpthread -rdynamic

LIBNAME = libthreadpool
SHARED_SUFFIX = .so
STATIC_SUFFIX = .a

ifdef DEBUG
CFLAGS += -g
endif

ifeq ($(strip $(PROFILE)),1)
CFLAGS += -DPROFILE
endif

SHARED = $(LIBNAME)$(SHARED_SUFFIX)
STATIC = $(LIBNAME)$(STATIC_SUFFIX)

TARGETS = $(SHARED) $(STATIC)

all: $(TARGETS)

OBJS := \
	src/threadpool.o

SORT_OBJS := \
	tests/list.o

SORT_DATA := \
	input.txt \
	output.txt \
	check.txt \
	sort_bench_*.txt \
	sort_bench_*.csv

deps := $(OBJS:%.o=%.o.d)
src/%.o: src/%.c
	$(CC) $(CFLAGS) -o $@ -MMD -MF $@.d -c $<

tests/%: tests/%.c $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

tests/list.o: tests/list.c
	$(CC) $(CFLAGS) -o $@ -MMD -MF $@.d -c $<

tests/input_generator: tests/input_generator.c
	$(CC) $(CFLAGS) -o $@ $^

tests/sort: tests/sort.c $(OBJS) $(SORT_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

TESTS =
#TESTS += tests/shutdown
#TESTS += tests/thrdtest
#TESTS += tests/heavy
TESTS += tests/mapreduce
TESTS += tests/sort

$(LIBNAME)$(SHARED_SUFFIX): $(OBJS)
	$(CC) -shared -o $@ $< ${LDLIBS}

$(LIBNAME)$(STATIC_SUFFIX): $(OBJS)
	$(AR) rcs $@ $^

clean:
	rm -f $(TARGETS) *~ */*~ $(OBJS) $(SORT_OBJS) \
		$(TESTS) tests/input_generator $(deps) core $(SORT_DATA)

test: $(TESTS)
check: $(TESTS)
	@for test in $^ ; \
	do \
		echo "Execute $$test..." ; $$test && echo "OK!\n" ; \
	done

sort: tests/sort tests/input_generator
	./tests/input_generator 10000 10000
	./tests/sort input.txt 32 256
	@sort -n input.txt > check.txt
	@diff output.txt check.txt && echo "sort testing succeed !"

sort_bench: tests/sort tests/input_generator
	rm sort_bench_*.txt sort_bench_*.csv \
		|| echo "sort data has been empty" \
		&& echo "clean sort data"
	@for i in `seq 500 500 10000`; do \
		./tests/input_generator $$i 10000; \
		for j in 1 2 4 8 16; do \
			echo sort $$i datas in input.txt with $$j thread, 256 queue_size ; \
			echo "[sort_num] $$i" >> sort_bench_$$j.txt ; \
			echo 3 | sudo tee /proc/sys/vm/drop_caches; \
			./tests/sort input.txt $$j 256 2>> sort_bench_$$j.txt ; \
		done; \
	done
	@for i in 1 2 4 8 16; do \
		./scripts/sort_bench_parse.py sort_bench_$$i.txt; \
	done
	gnuplot ./scripts/sort_runtime.gp

py:
	@for i in 1 2 4 8 16; do \
		./scripts/sort_bench_parse.py sort_bench_$$i.txt; \
	done

-include $(deps)
