# Contributing to kitchen-omnibus-chef

Thanks for your interest in improving kitchen-omnibus-chef. Bug reports, feature
requests, and pull requests are all welcome.

> **Note:** this gem is deprecated. See the deprecation notice in
> [README.md](README.md) for the recommended migration paths. Fixes are still
> welcome, but new features are better directed at
> [kitchen-chef-enterprise](https://github.com/chef/kitchen-chef-enterprise) or
> [kitchen-cinc](https://gitlab.com/cinc-project/kitchen-cinc).

## Reporting issues

Report bugs and request features on the
[issue tracker](https://github.com/test-kitchen/kitchen-omnibus-chef/issues). For
bugs, please include:

- the version of kitchen-omnibus-chef and Test Kitchen you are using
- which provisioner you are using (`chef_infra`, `chef_solo`, `chef_apply`,
  `chef_target`, or `chef_zero`)
- whether any of the enterprise or Cinc gems are also installed, since they
  change which implementation the `chef_*` names resolve to
- your `kitchen.yml`
- the output of the failing command, ideally with `-l debug`

## Development setup

```shell
git clone https://github.com/test-kitchen/kitchen-omnibus-chef.git
cd kitchen-omnibus-chef
bundle install
```

## Running the tests

```shell
bundle exec rake          # unit tests and linting
bundle exec rake spec     # unit tests only
bundle exec rake style    # Cookstyle / RuboCop only
```

Many style offenses can be corrected automatically:

```shell
bundle exec cookstyle -a
```

## Submitting changes

1. Fork the repository.
2. Create a feature branch off `main`.
3. Make your change, adding or updating tests to cover it.
4. Make sure `bundle exec rake` passes.
5. Push the branch to your fork and open a pull request.

Please keep pull requests focused on a single change — it makes review much
faster. Update the documentation in `README.md` when you add or change a
configuration option.

## Release Process

This release process applies to all Test Kitchen projects, but each project may have additional requirements.

1. Perform a GitHub diff between main and the last released version. Determine whether included PRs justify a patch, minor or major version release.
2. Check out the main branch of the project being prepared for release.
3. Branch into a release-branch of the form `150_release_prep`.
4. Modify the `version.rb` file to specify the version for releasing.
5. Run `rake changelog` to regenerate the changelog.
6. `git commit` the `version.rb` and `CHANGELOG.md` changes to the branch and setup a PR for them. Allow the PR to run any automated tests and review the CHANGELOG for accuracy.
7. Merge the PR to main after review.
8. Switch your local copy to the main branch and `git pull` to pull in the release preparation changes.
9. Run `rake release` on the main branch.
10. Modify the `version.rb` file and bump the patch or minor version, and commit/push.
