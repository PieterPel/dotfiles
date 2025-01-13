return {
    {
        'dgagn/diagflow.nvim',
        --event = 'LspAttach', --This is what the author uses personally        
        config = function ()
            require('diagflow').setup(
                {scope='line',
                placement='inline',
                inline_padding_left=3,
                }
            )
        end
    }
}
