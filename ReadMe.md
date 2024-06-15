# Rust Build Matrix Action

## Outputs

| Name | Description |
| ------- | ------- |
| `matrix` | The generated build matrix. |

```yaml
jobs:
  generate-matrix:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.generate-matrix.outputs.matrix }}
    steps:
      - name: Check out repository
        uses: actions/checkout@v4
      - name: Install toolchain
        uses: dtolnay/rust-toolchain@stable  
      - name: Generate build matrix
        uses: reitermarkus/rust-build-matrix@main
        id: generate-matrix
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      needs: generate-matrix
      matrix:
        include: ${{ fromJSON(needs.generate-matrix.outputs.matrix) }}
    steps:
      # ...
      - run: |
          cargo build --target "${target}"
        env:
          target: ${{ matrix.target }}
```
