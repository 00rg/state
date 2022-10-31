build_dir       := target
bin_dir         := $(build_dir)/bin
third_party_dir := $(build_dir)/third-party

##
## Ensure that the build directory exists.
##
$(build_dir):
	@mkdir -p $(build_dir)

##
## Ensure that the bin directory exists.
##
$(bin_dir):
	@mkdir -p $(bin_dir)

##
## Ensure that the third party download directory exists.
##
$(third_party_dir):
	@mkdir -p $(third_party_dir)

## Deletes the build directory.
.PHONY: clean
clean:
	@rm -rf $(build_dir)
