BUILD_DIR := build
SRC_DIR := src

SRC_DIR_FROM_BUILD_DIR := $(shell realpath --relative-to="$(BUILD_DIR)" "$(SRC_DIR)")

.PHONY: _build
_build: ${BUILD_DIR}/what-are-you-doing

.PHONY: clean
clean:
	find . \( -name '*.cmi' -o -name '*.cmx' -o -name '*.o' \) -print -delete
	rm -r ${BUILD_DIR}

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}

${BUILD_DIR}/what-are-you-doing: ${BUILD_DIR} ${SRC_DIR}/what-are-you-doing.ml Makefile
	cd ${BUILD_DIR} \
	&& ocamlopt \
		-ccopt -static \
		-pp 'sed "/^#/ d"' \
		-o what-are-you-doing \
		unix.cmxa \
		${SRC_DIR_FROM_BUILD_DIR}/what-are-you-doing.ml

