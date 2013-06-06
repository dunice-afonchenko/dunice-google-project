$(document).ready(function(){
    console.log('ready');
    $("a.selectAll").click(function(){
        $("input[name='scannerType']").each(function(){
            this.checked = true;
        });
        checkSearchType();
    });

    $("a.deselectAll").click(function(){
        $("input[name='scannerType']").each(function(){
            this.checked = false;
        });
        checkSearchType();
    });

    $("input[name='searchType']").change(function (){
        checkSearchType();
    });

    $("input[name='scannerType']").change(function () {
        checkSearchType();
    });
});

function checkSearchType() {
    if ($("input[value='radarSearch']").prop('checked') && $("input[name='scannerType']:checked").length == 0) {
        $("button[type='submit']").attr('disabled', 'disabled');
        $("p.radarWarning").css('display', 'block');
    } else {
        $("button[type='submit']").removeAttr('disabled');
        $("p.radarWarning").css('display', 'none');
    };
};

