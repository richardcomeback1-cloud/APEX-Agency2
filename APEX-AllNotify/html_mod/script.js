$(function () {

    var alert = new Audio('alert.mp3');
    alert.volume = 0.1;

    let notiid = 0
    let maxnoti = 2
    let deletenoti = 0

    const getAlertTheme = (icon) => {
        const value = (icon || '').toLowerCase();
        if (value.indexOf('ambulance') !== -1 || value.indexOf('medic') !== -1) {
            return 'ambulance';
        }
        if (value.indexOf('police') !== -1) {
            return 'police';
        }
        if (value.indexOf('gang') !== -1) {
            return 'gang';
        }
        return 'default';
    }

    const escapeHtml = (value) => {
        return String(value || '')
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    window.addEventListener('message', function(event) {
        var item = event.data;

        ///////////////////////////////////////////////////////// Notify

        if (item.type == "changeposition") {
            $(".notify").css({"right": ""+item.right+"%"});
            $(".alertmain").css({"right": ""+item.right+"%"});
        }

        if (item.type == "togglenotify") {
            // let color = "rgb(255, 0, 54)"
            // if (item.notify.type) {
            //     if (item.notify.type == "success") {
            //         color = "rgb(120, 171, 190)"
            //     }
            //     if (item.notify.type == "error") {
            //         color = "rgb(255, 255, 255, 0.6)"
            //     }
            //     if (item.notify.type == "warning") {
            //         color = "rgb(255, 185, 20)"
            //     }
            // }
            // $(".notify").append(`
            //     <div class="notifytoggle ${notiid}" id="${item.notify.id}" style="border-left: 2px solid ${color};">
            //         <div class="notitext">${item.notify.text}</div>
            //         <div class="borderloadtime" id="loadid_${item.notify.id}" style="width: 100%; transition: ${item.notify.time}ms; background-color: ${color}; box-shadow: 0px 0px 5px ${color};"></div>
            //     </div>
            // `);
            // $("#"+item.notify.id+"").show();

            // notiid = notiid + 1
            // if (notiid > maxnoti) {
            //     $("."+deletenoti+"").remove();
            //     deletenoti = deletenoti + 1
            // }

            // setTimeout(function() {
            //     $("#"+item.notify.id+"").css({"transform": "translateX(0%)","opacity": "100%"});

            //     $("#loadid_"+item.notify.id+"").css({"width": "0%", "transition": ""+item.notify.time+"ms"});

            //     setTimeout(function() {

            //         $("#"+item.notify.id+"").css({"transform": "translateX(120%)","opacity": "0%"});
            //         setTimeout(function() {
            //             $("#"+item.notify.id+"").remove();
            //         }, 350);
            //     }, item.notify.time);

            // }, 100);
            let color = "rgb(42, 63, 18, 0.8)"
            if (item.notify.type) {
                if (item.notify.type == "success") {
                    $(".notify").append(`
                        <div class="notifytoggle ${notiid}" id="${item.notify.id}">
                            <img src="img/success.png" class="notibox">
                            <div class="notitext">${item.notify.text}</div>
                        </div>
                    `);
                }
                if (item.notify.type == "error") {
                    $(".notify").append(`
                        <div class="notifytoggle ${notiid}" id="${item.notify.id}">
                            <img src="img/error2.png" class="notibox">
                            <div class="notitext">${item.notify.text}</div>
                        </div>
                    `);
                }
                if (item.notify.type == "warning") {
                    $(".notify").append(`
                        <div class="notifytoggle ${notiid}" id="${item.notify.id}">
                            <img src="img/warning.png" class="notibox">
                            <div class="notitext">${item.notify.text}</div>
                        </div>
                    `);
                }
            }

            $("#"+item.notify.id+"").show();

            notiid = notiid + 1
            if (notiid > maxnoti) {
                $("."+deletenoti+"").remove();
                deletenoti = deletenoti + 1
            }

            setTimeout(function() {
                $("#"+item.notify.id+"").css({"transform": "translateX(0%)","opacity": "100%"});

                setTimeout(function() {
                    $("#"+item.notify.id+"").css({"transform": "translateX(120%)","opacity": "0%"});
                    setTimeout(function() {
                        $("#"+item.notify.id+"").remove();
                    }, 350);
                }, item.notify.time);

            }, 100);
        }

        ///////////////////////////////////////////////////////// Notify

        ///////////////////////////////////////////////////////// Alert

        if (item.type == "add") {
            if (item.data) {
                const theme = getAlertTheme(item.data.icon)
                const wpKey = item.data.wp_key ? escapeHtml(item.data.wp_key) : '-'
                const text = escapeHtml(item.data.text)
                const zone = escapeHtml(item.data.zone)

                $(".alertlist").append(`
                    <div class="alert alert-enter theme-${theme}" id="${item.data.index}">
                        <div class="alert-glow"></div>
                        <div class="icon">
                            <span>${wpKey}</span>
                        </div>
                        <div class="control-btn"><div class="shift">SHIFT</div>+<div class="num-alert">${wpKey}</div></div>
                        <div class="infor-alert">
                            <span class="case-title">${text}</span>
                            <span class="case-location">LOCATION : ${zone}</span>
                        </div>
                        <div class="bg-bar">
                            <div class="load-bar">
                                <div class="timebar" id="bar${item.data.index}"></div>
                            </div>
                        </div>
                    </div>
                `);
                setTimeout(function() {
                    $("#"+item.data.index+"").css({
                        "transform": "translateX(0%)",
                        "opacity": "100%",
                    });
                    setTimeout(function() {
                        $("#"+item.data.index+"").removeClass('alert-enter');
                    }, 420);
                    alert.play();
                    $( "#bar"+item.data.index+"" ).animate({
                        width: "0%",
                    }, item.data.time*1000, function() {

                    });
                }, 100);
            }
        }
        if (item.type == "remove") {
            $("#"+item.id+"").css({
                "transform": "translateX(110%)",
                "opacity": "0%",
            });
            setTimeout(function() {
                $("#"+item.id+"").remove();
            }, 200);
        }
        ///////////////////////////////////////////////////////// Alert

        ///////////////////////////////////////////////////////// iTemsnotify
        if (item.type == "itemsnotify") {
            let color = `rgb(${item.color.R}, ${item.color.G}, ${item.color.B})`
            let Text = item.text
            $(".itemsnotify").append(`
                <div class="itemnotify" id="${item.id}">
                    <div class="bar" style="background-color:${color};box-shadow: 0px 0px 10px ${color};"></div>
                    <div class="bar" style="background-color:${color};box-shadow: 0px 0px 10px ${color};"></div>
                    <div class="itemimg"><img src="${item.inventoryLink}${item.name}.png"></div>
                    <div class="typename"><span>${item.label}</span></div>
                    <div class="amount"><span>${item.count}</span>${item.ea}</div>
                    <div class="showtype" style="background-color: ${color}; box-shadow: 0px 0px 5px ${color};"><span>${Text[item.action]}</span></div>
                </div>
            `);
            $("img").on("error", function () {
                $(this).attr("src", "error.png");
            });
            setTimeout(function() {
                $("#"+item.id+"").css({
                    "transform": "translateX(0%)",
                    "opacity": "100%",
                });
            }, 10);
            setTimeout(function() {
                $("#"+item.id+"").css({
                    "transform": "translateX(110%)",
                    "opacity": "0%",
                });
                setTimeout(function() {
                    $("#"+item.id+"").hide();
                    setTimeout(function() {
                        $("#"+item.id+"").remove();
                    }, 1000);
                }, 200);
            }, item.time);
        }
        ///////////////////////////////////////////////////////// iTemsnotify
    })

})
