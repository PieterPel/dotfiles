function dev --wraps='pushd ~/nix/standard; nix develop --command fish; popd' --description 'alias dev=pushd ~/nix/standard; nix develop --command fish; popd'
  pushd ~/nix/standard; nix develop --command fish; popd $argv
        
end
