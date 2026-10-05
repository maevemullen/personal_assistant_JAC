import "./styles.css";
import from .MosaicBackground { MosaicBackground }
import from .PlannerPage { PlannerPage }

def:pub app -> JsxElement {
    return <>
        <MosaicBackground/>
        <PlannerPage/>
    </>;
}
