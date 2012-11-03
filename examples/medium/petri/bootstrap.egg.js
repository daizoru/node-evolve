var code = evolve.mutable(function() {
    foo = foo * 1.0;
    mutation_rate = Math.cos(0.001) + Math.sin(0.5);
    mutation_rate = mutation_rate / foo;
    lifespan_rate = 0.0;
    forking_rate = 1.0;
    return;
});
code();

